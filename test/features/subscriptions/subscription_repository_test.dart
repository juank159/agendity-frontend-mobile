import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/network/api_client.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/features/subscriptions/data/datasources/subscription_remote_datasource.dart';
import 'package:login_signup/features/subscriptions/data/repositories/subscription_repository_impl.dart';
import 'package:login_signup/features/subscriptions/domain/entities/subscription_entity.dart';
import 'package:login_signup/features/subscriptions/domain/entities/subscription_limits.dart';
import 'package:login_signup/features/subscriptions/domain/failures/subscription_failures.dart';
import 'package:login_signup/features/subscriptions/domain/usecases/check_subscription_limits_usecase.dart';
import 'package:login_signup/features/subscriptions/domain/usecases/create_paid_subscription_usecase.dart';
import 'package:login_signup/features/subscriptions/domain/usecases/get_all_plans_usecase.dart';
import 'package:login_signup/features/subscriptions/domain/usecases/get_current_subscription_usecase.dart';
import 'package:login_signup/features/subscriptions/domain/usecases/refresh_subscription_status_usecase.dart';

import '../../core/network/fake_http_client_adapter.dart';
import '../../core/session/memory_token_store.dart';
import 'subscription_models_test.dart'
    show
        backendActive,
        backendCheckout,
        backendLimits,
        backendPlan,
        backendTrialWithPendingPayment;

Failure? leftOf(Either<Failure, Object?> result) =>
    result.fold((f) => f, (_) => null);

T rightOf<T>(Either<Failure, T> result) =>
    result.getOrElse(() => throw StateError('Left: ${leftOf(result)}'));

ResponseBody forbidden() => jsonBody(403, {
      'statusCode': 403,
      'code': 'FORBIDDEN',
      'message': 'No tienes permiso para realizar esta acción',
    });

void main() {
  late FakeHttpClientAdapter adapter;
  late SubscriptionRepositoryImpl repository;

  setUp(() {
    adapter = FakeHttpClientAdapter((_) => jsonBody(200, []));
    final dio = buildApiClient(
      baseUrl: 'http://api.test/api',
      tokenStore: MemoryTokenStore('jwt'),
      httpClientAdapter: adapter,
      retryDelay: (_) => Duration.zero,
      enableLogs: false,
    );
    repository =
        SubscriptionRepositoryImpl(SubscriptionRemoteDataSourceImpl(dio));
  });

  group('SubscriptionRepositoryImpl (Dio api + adaptador falso)', () {
    test('GET /plans: entidades, token del núcleo y sin tenant-id', () async {
      adapter.handler = (_) => jsonBody(200, [backendPlan()]);
      final plans = rightOf(await repository.getPlans());
      expect(plans.single.price, 29900);
      final request = adapter.requests.single;
      expect('${request.method} ${request.uri.path}',
          'GET /api/subscriptions/plans');
      expect(request.headers['Authorization'], 'Bearer jwt');
      expect(request.headers.containsKey('tenant-id'), false);
    });

    test('GET /status: trial con pago pendiente', () async {
      adapter.handler = (_) => jsonBody(200, backendTrialWithPendingPayment());
      final status = rightOf(await repository.getStatus());
      expect(status.status, SubscriptionStatus.trial);
      expect(status.pendingPayment!.planId, 'plan-1');
      expect(adapter.requests.single.uri.path, '/api/subscriptions/status');
    });

    test('GET /check-limits: bloqueo tipado', () async {
      adapter.handler = (_) => jsonBody(
          200,
          backendLimits(
              can: false,
              message: 'Has alcanzado el límite de citas de prueba.',
              code: 'TRIAL_LIMIT_REACHED'));
      final limits = rightOf(await repository.checkLimits());
      expect(limits.block, SubscriptionBlock.trialLimitReached);
      expect(
          adapter.requests.single.uri.path, '/api/subscriptions/check-limits');
    });

    test('POST /subscribe (201): plan y redirect, SIN tenant_id', () async {
      adapter.handler = (_) => jsonBody(201, backendCheckout());
      final checkout = rightOf(await repository.subscribe('plan-1'));
      expect(checkout.paymentLink, 'https://checkout.wompi.co/l/abc123');
      final request = adapter.requests.single;
      expect('${request.method} ${request.uri.path}',
          'POST /api/subscriptions/subscribe');
      expect(request.data, {
        'plan_id': 'plan-1',
        'redirect_url': SubscriptionRemoteDataSourceImpl.paymentRedirectUrl,
      });
    });

    test('POST /subscribe sin enlace → PaymentLinkUnavailableFailure',
        () async {
      for (final link in [null, '', '  ']) {
        adapter.handler = (_) => jsonBody(201, backendCheckout(link: link));
        expect(leftOf(await repository.subscribe('plan-1')),
            isA<PaymentLinkUnavailableFailure>(),
            reason: '$link');
      }
    });

    test('POST /refresh-status (200)', () async {
      adapter.handler = (_) => jsonBody(200, {
            'success': true,
            'message': 'Suscripción verificada y activada correctamente',
          });
      expect(rightOf(await repository.refreshStatus()).activated, true);
      expect(
          '${adapter.requests.single.method} '
              '${adapter.requests.single.uri.path}',
          'POST /api/subscriptions/refresh-status');
    });

    test('403 del Employee en subscribe y refresh → ForbiddenFailure',
        () async {
      adapter.handler = (_) => forbidden();
      expect(leftOf(await repository.subscribe('plan-1')),
          isA<ForbiddenFailure>());
      expect(leftOf(await repository.refreshStatus()), isA<ForbiddenFailure>());
    });

    test(
        'TRIAL_LIMIT_REACHED / SUBSCRIPTION_INACTIVE (HTTP legado 400) → '
        'failures propios por code', () async {
      adapter.handler = (_) => jsonBody(400, {
            'statusCode': 400,
            'code': 'TRIAL_LIMIT_REACHED',
            'message': 'Has alcanzado el límite de citas de prueba.',
          });
      final trial = leftOf(await repository.checkLimits());
      expect(trial, isA<TrialLimitReachedFailure>());
      expect(trial, isA<PaymentRequiredFailure>());
      expect(trial!.message, 'Has alcanzado el límite de citas de prueba.');
      expect(trial.statusCode, 400);

      adapter.handler = (_) => jsonBody(402, {
            'statusCode': 402,
            'code': 'SUBSCRIPTION_INACTIVE',
            'message': 'Tu suscripción no está activa.',
          });
      expect(leftOf(await repository.getStatus()),
          isA<SubscriptionInactiveFailure>());
    });

    test('402 sin code → PaymentRequiredFailure genérico (no se adivina)', () {
      const generic = PaymentRequiredFailure(statusCode: 402);
      expect(refineSubscriptionFailure(generic), same(generic));
    });

    test('sin red: GET reintenta; POST no', () async {
      adapter.handler = connectionError;
      expect(leftOf(await repository.getStatus()), isA<NetworkFailure>());
      expect(adapter.requests, hasLength(4));
      adapter.requests.clear();
      expect(
          leftOf(await repository.subscribe('plan-1')), isA<NetworkFailure>());
      expect(adapter.requests, hasLength(1));
    });

    test('500 o forma inesperada → ServerFailure, sin excepción', () async {
      adapter.handler = (_) => jsonBody(500, {'statusCode': 500});
      expect(leftOf(await repository.getPlans()), isA<ServerFailure>());
      adapter.handler = (_) => jsonBody(200, {'unexpected': true});
      expect(leftOf(await repository.getPlans()), isA<ServerFailure>());
    });
  });

  group('Use cases', () {
    test('GetAllPlans ordena por duración y precio', () async {
      adapter.handler = (_) => jsonBody(200, [
            backendPlan(id: 'anual', durationMonths: 12, price: '250000'),
            backendPlan(id: 'mensual-b', durationMonths: 1, price: '39900'),
            backendPlan(id: 'semestral', durationMonths: 6, price: '150000'),
            backendPlan(id: 'mensual-a', durationMonths: 1, price: '29900'),
          ]);
      final plans = rightOf(await GetAllPlansUseCase(repository)(NoParams()));
      expect(plans.map((p) => p.id),
          ['mensual-a', 'mensual-b', 'semestral', 'anual']);
    });

    test('GetCurrentSubscription y CheckSubscriptionLimits delegan', () async {
      adapter.handler = (_) => jsonBody(200, backendActive());
      expect(
          rightOf(await GetCurrentSubscriptionUseCase(repository)(NoParams()))
              .isActive,
          true);
      adapter.handler = (_) => jsonBody(200, backendLimits());
      expect(
          rightOf(await CheckSubscriptionLimitsUseCase(repository)(NoParams()))
              .canCreateAppointment,
          true);
    });

    test('CreatePaidSubscription: plan vacío → ValidationFailure sin backend',
        () async {
      final failure =
          leftOf(await CreatePaidSubscriptionUseCase(repository)('  '));
      expect(failure, isA<ValidationFailure>());
      expect(
          failure!.message, CreatePaidSubscriptionUseCase.missingPlanMessage);
      expect(adapter.requests, isEmpty);
    });

    test('RefreshSubscriptionStatus: sin cambios → activated false', () async {
      adapter.handler = (_) => jsonBody(200, {
            'success': false,
            'message': 'No se encontraron cambios en la suscripción',
          });
      expect(
          rightOf(await RefreshSubscriptionStatusUseCase(repository)(
                  NoParams()))
              .activated,
          false);
    });
  });
}
