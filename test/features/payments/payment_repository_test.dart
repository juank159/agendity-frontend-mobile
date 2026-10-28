import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:login_signup/common/enums/payment_method_enum.dart';
import 'package:login_signup/common/enums/payment_status_enum.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/network/api_client.dart';
import 'package:login_signup/features/payments/data/datasources/payment_remote_datasource.dart';
import 'package:login_signup/features/payments/data/repositories/payment_repository_impl.dart';
import 'package:login_signup/features/payments/data/models/custom_payment_method_model.dart';
import 'package:login_signup/features/payments/domain/entities/custom_payment_method.dart';
import 'package:login_signup/features/payments/domain/entities/payment_entity.dart';
import 'package:login_signup/features/payments/domain/failures/payment_failures.dart';
import 'package:login_signup/features/payments/domain/repositories/payment_repository.dart';
import 'package:login_signup/features/payments/domain/usecases/create_payment_usecase.dart';
import 'package:login_signup/features/payments/domain/usecases/get_active_custom_payment_methods_usecase.dart';
import 'package:login_signup/core/usecases/usecase.dart';

import '../../core/network/fake_http_client_adapter.dart';
import '../../core/session/memory_token_store.dart';
import 'payment_model_test.dart' show backendPayment;

const newPayment = PaymentEntity(
  appointmentId: 'a1',
  amount: 50000,
  paymentMethod: PaymentMethod.CASH,
);

Failure? leftOf(Either<Failure, Object?> result) =>
    result.fold((f) => f, (_) => null);

/// Repositorio falso para el use case: guarda lo recibido.
class _RecordingRepository implements PaymentRepository {
  final List<PaymentEntity> received = [];

  @override
  Future<Either<Failure, PaymentEntity>> createPayment(
      PaymentEntity payment) async {
    received.add(payment);
    return Right(payment.copyWith(id: 'p1', status: PaymentStatus.COMPLETED));
  }

  @override
  Future<Either<Failure, List<CustomPaymentMethod>>>
      getActiveCustomPaymentMethods() async =>
          const Right([CustomPaymentMethod(id: 'cm-1', name: 'Nequi')]);
}

/// Respuesta real de `GET /custom-payment-methods/active`.
const backendCustomMethod = {
  'id': 'cm-1',
  'ownerId': 'owner-1',
  'name': 'Nequi',
  'description': null,
  'icon': 'phone',
  'isActive': true,
  'created_at': '2026-10-21T08:00:00.000-05:00',
  'updated_at': '2026-10-21T08:00:00.000-05:00',
};

void main() {
  group('PaymentRepositoryImpl (Dio api + adaptador falso)', () {
    late FakeHttpClientAdapter adapter;
    late PaymentRepositoryImpl repository;

    setUp(() {
      adapter = FakeHttpClientAdapter((_) => jsonBody(201, backendPayment()));
      final dio = buildApiClient(
        baseUrl: 'http://api.test/api',
        tokenStore: MemoryTokenStore('jwt'),
        httpClientAdapter: adapter,
        retryDelay: (_) => Duration.zero,
        enableLogs: false,
      );
      repository = PaymentRepositoryImpl(PaymentRemoteDataSourceImpl(dio));
    });

    test('éxito (201): POST /payments con token del núcleo y el DTO',
        () async {
      final result = await repository.createPayment(newPayment);
      final payment = result.getOrElse(() => throw StateError('Left'));
      expect(payment.id, 'p1');
      expect(payment.appointmentId, 'a1');
      expect(payment.status, PaymentStatus.COMPLETED);

      final request = adapter.requests.single;
      expect(request.method, 'POST');
      expect(request.uri.path, '/api/payments');
      expect(request.headers['Authorization'], 'Bearer jwt');
      expect(request.headers.containsKey('tenant-id'), false);
      expect(request.data, {
        'appointment_id': 'a1',
        'amount': 50000.0,
        'payment_method': 'CASH',
      });
    });

    test('409 INVALID_STATE_TRANSITION (cita cancelada) → AppointmentNotPayable',
        () async {
      adapter.handler = (_) => jsonBody(409, {
            'statusCode': 409,
            'code': 'INVALID_STATE_TRANSITION',
            'message': 'No se puede registrar un pago en una cita cancelada',
          });
      final failure = leftOf(await repository.createPayment(newPayment));
      expect(failure, isA<AppointmentNotPayableFailure>());
      expect(failure, isA<ConflictFailure>());
      expect(failure!.message,
          'No se puede registrar un pago en una cita cancelada');
      expect(failure.statusCode, 409);
    });

    test('409 CONFLICT genérico → ConflictFailure (sin refinar)', () async {
      adapter.handler = (_) => jsonBody(
          409, {'statusCode': 409, 'code': 'CONFLICT', 'message': 'Conflicto'});
      final failure = leftOf(await repository.createPayment(newPayment));
      expect(failure, isA<ConflictFailure>());
      expect(failure, isNot(isA<AppointmentNotPayableFailure>()));
    });

    test('400 VALIDATION_ERROR → ValidationFailure con details', () async {
      adapter.handler = (_) => jsonBody(400, {
            'statusCode': 400,
            'code': 'VALIDATION_ERROR',
            'message': 'amount must be a positive number',
            'details': ['amount must be a positive number'],
          });
      final failure = leftOf(await repository.createPayment(newPayment));
      expect(failure, isA<ValidationFailure>());
      expect(failure!.details, ['amount must be a positive number']);
    });

    test('409 PAYMENT_ALREADY_EXISTS (cita ya pagada) → ConflictFailure',
        () async {
      adapter.handler = (_) => jsonBody(409, {
            'statusCode': 409,
            'code': 'PAYMENT_ALREADY_EXISTS',
            'message': 'Ya existe un pago completado para esta cita',
          });
      final failure = leftOf(await repository.createPayment(newPayment));
      expect(failure, isA<ConflictFailure>());
      expect(failure, isNot(isA<AppointmentNotPayableFailure>()));
      expect(failure!.code, ApiErrorCode.paymentAlreadyExists);
      expect(failure.message, 'Ya existe un pago completado para esta cita');
    });

    test('403 (Employee) → ForbiddenFailure', () async {
      adapter.handler =
          (_) => jsonBody(403, {'statusCode': 403, 'code': 'FORBIDDEN'});
      expect(leftOf(await repository.createPayment(newPayment)),
          isA<ForbiddenFailure>());
    });

    test('sin red → NetworkFailure, sin reintentar el POST', () async {
      adapter.handler = connectionError;
      expect(leftOf(await repository.createPayment(newPayment)),
          isA<NetworkFailure>());
      expect(adapter.requests, hasLength(1));
    });

    test('respuesta vacía → ServerFailure, sin excepción', () async {
      adapter.handler = (_) => ResponseBody.fromString('', 201);
      expect(leftOf(await repository.createPayment(newPayment)),
          isA<ServerFailure>());
    });
  });

  group('CreatePaymentUseCase', () {
    late _RecordingRepository repository;
    late CreatePaymentUseCase useCase;

    setUp(() {
      repository = _RecordingRepository();
      useCase = CreatePaymentUseCase(repository);
    });

    CreatePaymentParams params({
      double amount = 50000,
      double? total = 50000,
      PaymentMethod method = PaymentMethod.CASH,
      String? customId,
      String? transactionId,
    }) =>
        CreatePaymentParams(
          appointmentId: 'a1',
          amount: amount,
          method: method,
          customPaymentMethodId: customId,
          transactionId: transactionId,
          appointmentTotal: total,
        );

    test('válido: construye la entidad y llama al repositorio', () async {
      final result = await useCase(
          params(method: PaymentMethod.TRANSFER, transactionId: '  TRX9 '));
      expect(result.isRight(), true);
      expect(
          repository.received.single,
          const PaymentEntity(
            appointmentId: 'a1',
            amount: 50000,
            paymentMethod: PaymentMethod.TRANSFER,
            transactionId: 'TRX9',
          ));
    });

    test('transactionId vacío y customId de un método estándar no viajan',
        () async {
      await useCase(params(transactionId: '', customId: 'c1'));
      expect(repository.received.single.transactionId, isNull);
      expect(repository.received.single.customPaymentMethodId, isNull);
    });

    test('monto ≤ 0 → InvalidPaymentAmountFailure sin llamar al backend',
        () async {
      for (final amount in [0.0, -5.0, 0.001, double.nan]) {
        final failure = leftOf(await useCase(params(amount: amount)));
        expect(failure, isA<InvalidPaymentAmountFailure>());
        expect(failure!.message, InvalidPaymentAmountFailure.notPositiveMessage);
      }
      expect(repository.received, isEmpty);
    });

    test('monto mayor que el total → InvalidPaymentAmountFailure', () async {
      final failure =
          leftOf(await useCase(params(amount: 50000.01, total: 50000)));
      expect(failure, isA<InvalidPaymentAmountFailure>());
      expect(failure!.message, InvalidPaymentAmountFailure.exceedsTotalMessage);
      expect(repository.received, isEmpty);
    });

    test('más de 2 decimales → InvalidPaymentAmountFailure', () async {
      final failure = leftOf(await useCase(params(amount: 100.555)));
      expect(failure!.message,
          InvalidPaymentAmountFailure.tooManyDecimalsMessage);
    });

    test('sin total conocido solo valida > 0', () async {
      expect((await useCase(params(amount: 999999, total: null))).isRight(),
          true);
    });

    test('CUSTOM sin método propio → ValidationFailure', () async {
      final failure =
          leftOf(await useCase(params(method: PaymentMethod.CUSTOM)));
      expect(failure, isA<ValidationFailure>());
      expect(repository.received, isEmpty);
      expect(
          (await useCase(params(method: PaymentMethod.CUSTOM, customId: 'c1')))
              .isRight(),
          true);
      expect(repository.received.single.customPaymentMethodId, 'c1');
    });
  });

  group('CustomPaymentMethodModel', () {
    test('fromJson con la respuesta real del backend', () {
      expect(
          CustomPaymentMethodModel.fromJson(backendCustomMethod).toEntity(),
          const CustomPaymentMethod(id: 'cm-1', name: 'Nequi', icon: 'phone'));
    });

    test('tolerante: nulls, vacíos e isActive como texto', () {
      final model = CustomPaymentMethodModel.fromJson(
          {'id': 7, 'name': ' Daviplata ', 'description': '', 'isActive': 'false'});
      expect(model.id, '7');
      expect(model.name, 'Daviplata');
      expect(model.description, isNull);
      expect(model.isActive, false);
      expect(CustomPaymentMethodModel.fromJson({}).isActive, true);
    });

    test('fromEntity/toEntity ida y vuelta', () {
      const entity = CustomPaymentMethod(
          id: 'cm-1', name: 'Nequi', description: 'd', isActive: false);
      expect(CustomPaymentMethodModel.fromEntity(entity).toEntity(), entity);
    });
  });

  group('getActiveCustomPaymentMethods (repositorio)', () {
    late FakeHttpClientAdapter adapter;
    late PaymentRepositoryImpl repository;

    setUp(() {
      adapter =
          FakeHttpClientAdapter((_) => jsonBody(200, [backendCustomMethod]));
      repository = PaymentRepositoryImpl(PaymentRemoteDataSourceImpl(
          buildApiClient(
        baseUrl: 'http://api.test/api',
        tokenStore: MemoryTokenStore('jwt'),
        httpClientAdapter: adapter,
        retryDelay: (_) => Duration.zero,
        enableLogs: false,
      )));
    });

    test('éxito: GET /custom-payment-methods/active → entidades', () async {
      final result = await repository.getActiveCustomPaymentMethods();
      expect(result.getOrElse(() => []),
          const [CustomPaymentMethod(id: 'cm-1', name: 'Nequi', icon: 'phone')]);
      final request = adapter.requests.single;
      expect(request.method, 'GET');
      expect(request.uri.path, '/api/custom-payment-methods/active');
      expect(request.headers['Authorization'], 'Bearer jwt');
    });

    test('lista vacía → Right([])', () async {
      adapter.handler = (_) => jsonBody(200, []);
      final result = await repository.getActiveCustomPaymentMethods();
      expect(result.isRight(), true);
      expect(result.getOrElse(() => [const CustomPaymentMethod(id: 'x', name: 'x')]),
          isEmpty);
    });

    test('403 (Employee) → ForbiddenFailure', () async {
      adapter.handler = (_) => jsonBody(403, {
            'statusCode': 403,
            'code': 'FORBIDDEN',
            'message': 'No tienes permiso'
          });
      expect(leftOf(await repository.getActiveCustomPaymentMethods()),
          isA<ForbiddenFailure>());
    });

    test('use case delega en el repositorio', () async {
      final result = await GetActiveCustomPaymentMethodsUseCase(
              _RecordingRepository())
          .call(NoParams());
      expect(result.getOrElse(() => []).single.name, 'Nequi');
    });
  });
}
