import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/network/api_client.dart';
import 'package:login_signup/features/statistics/data/datasources/statistics_remote_datasource.dart';
import 'package:login_signup/features/statistics/data/repositories/statistics_repository_impl.dart';
import 'package:login_signup/features/statistics/domain/entities/employee_stats_entity.dart';
import 'package:login_signup/features/statistics/domain/entities/payment_stats_entity.dart';
import 'package:login_signup/features/statistics/domain/entities/stats_range.dart';
import 'package:login_signup/features/statistics/domain/failures/statistics_failures.dart';
import 'package:login_signup/features/statistics/domain/usecases/get_employee_stats_usecase.dart';
import 'package:login_signup/features/statistics/domain/usecases/get_payment_comparison_usecase.dart';
import 'package:login_signup/features/statistics/domain/usecases/get_payment_stats_by_client_usecase.dart';
import 'package:login_signup/features/statistics/domain/usecases/get_payment_stats_by_method_usecase.dart';
import 'package:login_signup/features/statistics/domain/usecases/get_payment_stats_by_professional_usecase.dart';
import 'package:login_signup/features/statistics/domain/usecases/get_payment_stats_by_service_usecase.dart';
import 'package:login_signup/features/statistics/domain/usecases/get_payment_stats_usecase.dart';
import 'package:login_signup/features/statistics/domain/usecases/get_top_clients_usecase.dart';
import 'package:login_signup/features/statistics/domain/usecases/stats_use_case.dart';

import '../../core/network/fake_http_client_adapter.dart';
import '../../core/session/memory_token_store.dart';
import 'statistics_models_test.dart'
    show
        backendClientStats,
        backendComparison,
        backendEmployeeStats,
        backendEmptyEmployeeStats,
        backendMethodStats,
        backendPaymentStats,
        backendProfessionalStats,
        backendServiceStats,
        backendTopClient;

Failure? leftOf(Either<Failure, Object?> result) =>
    result.fold((f) => f, (_) => null);

T rightOf<T>(Either<Failure, T> result) =>
    result.getOrElse(() => throw StateError('Left: ${leftOf(result)}'));

/// Del 1 al 21 de octubre; las horas no cuentan (solo el día).
final october = StatsRange(
  start: DateTime(2026, 10, 1, 15, 30),
  end: DateTime(2026, 10, 21, 23, 59, 59),
);

ResponseBody forbidden() => jsonBody(403, {
      'statusCode': 403,
      'code': 'FORBIDDEN',
      'message': 'No tienes permiso para realizar esta acción',
    });

void main() {
  late FakeHttpClientAdapter adapter;
  late StatisticsRepositoryImpl repository;

  setUp(() {
    adapter = FakeHttpClientAdapter((_) => jsonBody(200, []));
    final dio = buildApiClient(
      baseUrl: 'http://api.test/api',
      tokenStore: MemoryTokenStore('jwt'),
      httpClientAdapter: adapter,
      retryDelay: (_) => Duration.zero,
      enableLogs: false,
    );
    repository = StatisticsRepositoryImpl(StatisticsRemoteDataSourceImpl(dio));
  });

  group('StatisticsRepositoryImpl (Dio api + adaptador falso)', () {
    test('GET /payments/stats: días yyyy-MM-dd, token del núcleo, sin tenant',
        () async {
      adapter.handler = (_) => jsonBody(200, backendPaymentStats());
      final stats = rightOf(await repository.getPaymentStats(october));
      expect(stats.totalAmount, 105000);

      final request = adapter.requests.single;
      expect(request.method, 'GET');
      expect(request.uri.path, '/api/payments/stats');
      expect(request.uri.queryParameters,
          {'startDate': '2026-10-01', 'endDate': '2026-10-21'});
      expect(request.headers['Authorization'], 'Bearer jwt');
      expect(request.headers.containsKey('tenant-id'), false);
    });

    test('las 8 rutas y sus parámetros', () async {
      adapter.handler = (options) => switch (options.uri.path) {
            '/api/payments/stats' => jsonBody(200, backendPaymentStats()),
            '/api/payments/stats/comparison' =>
              jsonBody(200, backendComparison()),
            '/api/payments/stats/by-method' =>
              jsonBody(200, [backendMethodStats()]),
            '/api/payments/stats/by-professional' =>
              jsonBody(200, [backendProfessionalStats()]),
            '/api/payments/stats/by-service' =>
              jsonBody(200, [backendServiceStats()]),
            '/api/payments/stats/by-client' =>
              jsonBody(200, [backendClientStats()]),
            '/api/payments/stats/top-clients' =>
              jsonBody(200, [backendTopClient()]),
            '/api/payments/employee-stats' =>
              jsonBody(200, backendEmployeeStats()),
            _ => jsonBody(404, {'statusCode': 404, 'code': 'NOT_FOUND'}),
          };

      expect(
          rightOf(await repository.getPaymentComparison(october))
              .change
              .countDifference,
          3);
      expect(rightOf(await repository.getPaymentStatsByMethod(october)),
          hasLength(1));
      expect(
          rightOf(await repository.getPaymentStatsByProfessional(october))
              .single
              .professionalName,
          'Laura');
      expect(rightOf(await repository.getPaymentStatsByService(october)),
          hasLength(1));
      expect(
          rightOf(await repository.getPaymentStatsByClient(october, limit: 20))
              .single
              .frequencyDays,
          10);
      expect(rightOf(await repository.getTopClients(october, limit: 5)),
          hasLength(1));
      expect(
          rightOf(await repository.getEmployeeStats(october,
                  professionalId: 'pro-1'))
              .summary
              .paymentCount,
          2);

      final byPath = {
        for (final r in adapter.requests) r.uri.path: r.uri.queryParameters
      };
      expect(byPath['/api/payments/stats/by-client']!['limit'], '20');
      expect(byPath['/api/payments/stats/top-clients']!['limit'], '5');
      expect(byPath['/api/payments/employee-stats'], {
        'startDate': '2026-10-01',
        'endDate': '2026-10-21',
        'professionalId': 'pro-1',
      });
    });

    test('employee-stats del Employee: sin professionalId', () async {
      adapter.handler = (_) => jsonBody(200, backendEmployeeStats());
      rightOf(await repository.getEmployeeStats(october));
      expect(adapter.requests.single.uri.queryParameters.keys,
          unorderedEquals(['startDate', 'endDate']));
    });

    test('403 del Employee en las rutas del negocio → ForbiddenFailure',
        () async {
      adapter.handler = (_) => forbidden();
      final results = <Either<Failure, Object?>>[
        await repository.getPaymentStats(october),
        await repository.getPaymentComparison(october),
        await repository.getPaymentStatsByMethod(october),
        await repository.getPaymentStatsByProfessional(october),
        await repository.getPaymentStatsByService(october),
        await repository.getPaymentStatsByClient(october, limit: 10),
        await repository.getTopClients(october, limit: 5),
      ];
      for (final result in results) {
        final failure = leftOf(result);
        expect(failure, isA<ForbiddenFailure>());
        expect(failure!.statusCode, 403);
      }
    });

    test('rango sin pagos: ceros y listas vacías, no error', () async {
      adapter.handler = (options) => switch (options.uri.path) {
            '/api/payments/stats' => jsonBody(
                200, backendPaymentStats(total: 0, count: 0, average: 0)),
            '/api/payments/employee-stats' =>
              jsonBody(200, backendEmptyEmployeeStats()),
            _ => jsonBody(200, []),
          };
      expect(rightOf(await repository.getPaymentStats(october)),
          PaymentStatsEntity.empty);
      expect(rightOf(await repository.getPaymentStatsByProfessional(october)),
          isEmpty);
      expect(
          rightOf(await repository.getTopClients(october, limit: 5)), isEmpty);
      expect(rightOf(await repository.getEmployeeStats(october)),
          const EmployeeStatsEntity());
    });

    test('400 del Owner sin professionalId → ValidationFailure', () async {
      adapter.handler = (_) => jsonBody(400, {
            'statusCode': 400,
            'code': 'BAD_REQUEST',
            'message': 'Se requiere professionalId para consultar '
                'estadísticas de un profesional específico',
          });
      final failure = leftOf(await repository.getEmployeeStats(october));
      expect(failure, isA<ValidationFailure>());
      expect(failure!.message, startsWith('Se requiere professionalId'));
    });

    test('sin red: reintenta el GET y da NetworkFailure', () async {
      adapter.handler = connectionError;
      expect(leftOf(await repository.getPaymentStats(october)),
          isA<NetworkFailure>());
      expect(adapter.requests, hasLength(4));
    });

    test('500 o respuesta con otra forma → ServerFailure, sin excepción',
        () async {
      adapter.handler = (_) => jsonBody(500, {'statusCode': 500});
      expect(leftOf(await repository.getPaymentStats(october)),
          isA<ServerFailure>());
      adapter.handler = (_) => jsonBody(200, {'unexpected': true});
      expect(leftOf(await repository.getTopClients(october, limit: 5)),
          isA<ServerFailure>());
      adapter.handler = (_) => jsonBody(200, {'current_period': null});
      expect(leftOf(await repository.getPaymentComparison(october)),
          isA<ServerFailure>());
    });
  });

  group('Use cases (sobre el repositorio real y el adaptador falso)', () {
    final inverted = StatsRange(
        start: DateTime(2026, 10, 21), end: DateTime(2026, 10, 20, 23));

    test('delegan en el repositorio con el rango', () async {
      adapter.handler = (_) => jsonBody(200, backendPaymentStats());
      expect(
          rightOf(await GetPaymentStatsUseCase(repository)(october))
              .paymentCount,
          3);
      adapter.handler = (_) => jsonBody(200, [backendTopClient()]);
      expect(
          rightOf(await GetTopClientsUseCase(repository)(
              StatsRankingParams(october, limit: 5))),
          hasLength(1));
      adapter.handler = (_) => jsonBody(200, backendEmployeeStats());
      expect(
          (await GetEmployeeStatsUseCase(repository)(
                  EmployeeStatsParams(october)))
              .isRight(),
          true);
    });

    test('un solo día (inicio y fin iguales, distinta hora) es válido',
        () async {
      adapter.handler = (_) => jsonBody(200, backendPaymentStats());
      final today = StatsRange(
          start: DateTime(2026, 10, 21, 18), end: DateTime(2026, 10, 21, 8));
      expect(today.isValid, true);
      expect((await GetPaymentStatsUseCase(repository)(today)).isRight(), true);
      expect(StatsRange.day(DateTime(2026, 10, 21)), today);
    });

    test('rango invertido → InvalidStatsQueryFailure sin llamar al backend',
        () async {
      final results = <Either<Failure, Object?>>[
        await GetPaymentStatsUseCase(repository)(inverted),
        await GetPaymentComparisonUseCase(repository)(inverted),
        await GetPaymentStatsByMethodUseCase(repository)(inverted),
        await GetPaymentStatsByProfessionalUseCase(repository)(inverted),
        await GetPaymentStatsByServiceUseCase(repository)(inverted),
        await GetPaymentStatsByClientUseCase(repository)(
            StatsRankingParams(inverted, limit: 10)),
        await GetTopClientsUseCase(repository)(
            StatsRankingParams(inverted, limit: 5)),
        await GetEmployeeStatsUseCase(repository)(
            EmployeeStatsParams(inverted)),
      ];
      for (final result in results) {
        final failure = leftOf(result);
        expect(failure, isA<InvalidStatsQueryFailure>());
        expect(failure, isA<ValidationFailure>());
        expect(failure!.message, InvalidStatsQueryFailure.invalidRangeMessage);
      }
      expect(adapter.requests, isEmpty);
    });

    test('límite < 1 → InvalidStatsQueryFailure sin llamar al backend',
        () async {
      final failure = leftOf(await GetTopClientsUseCase(repository)(
          StatsRankingParams(october, limit: 0)));
      expect(failure, isA<InvalidStatsQueryFailure>());
      expect(failure!.message, InvalidStatsQueryFailure.invalidLimitMessage);
      expect(adapter.requests, isEmpty);
    });
  });
}
