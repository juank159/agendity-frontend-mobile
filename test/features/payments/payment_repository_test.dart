import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:login_signup/common/enums/payment_method_enum.dart';
import 'package:login_signup/common/enums/payment_status_enum.dart';
import 'package:login_signup/core/database/app_database.dart';
import 'package:login_signup/core/database/document_store.dart';
import 'package:login_signup/core/database/local_database_holder.dart';
import 'package:login_signup/core/database/shared_documents.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/sync/offline_store.dart';
import 'package:login_signup/core/sync/outbox_store.dart';
import 'package:login_signup/core/sync/sync_engine.dart';
import 'package:login_signup/core/sync/sync_models.dart';
import 'package:login_signup/features/appointments/data/sync/appointments_sync.dart';
import 'package:login_signup/features/payments/data/models/payment_model.dart';
import 'package:login_signup/features/payments/data/sync/payments_sync.dart';
import 'package:login_signup/features/payments/domain/usecases/get_payments_in_review_usecase.dart';
import 'package:login_signup/features/payments/data/repositories/payment_repository_impl.dart';
import 'package:login_signup/features/payments/data/models/custom_payment_method_model.dart';
import 'package:login_signup/features/payments/domain/entities/custom_payment_method.dart';
import 'package:login_signup/features/payments/domain/entities/payment_entity.dart';
import 'package:login_signup/features/payments/domain/failures/payment_failures.dart';
import 'package:login_signup/features/payments/domain/repositories/payment_repository.dart';
import 'package:login_signup/features/payments/domain/usecases/create_payment_usecase.dart';
import 'package:login_signup/features/payments/domain/usecases/get_active_custom_payment_methods_usecase.dart';
import 'package:login_signup/features/payments/domain/usecases/get_appointment_balance_usecase.dart';
import 'package:login_signup/features/payments/domain/entities/appointment_balance.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/features/payments/domain/usecases/refund_payment_usecase.dart';

import '../../core/sync/fake_sync_api.dart';
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

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
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

  @override
  Future<Either<Failure, List<PaymentEntity>>> getAppointmentPayments(
          String appointmentId) async =>
      const Right([]);
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
  late LocalDatabaseHolder databases;
  late AppDatabase db;
  late PaymentRepositoryImpl repository;
  var ids = 0;

  /// Cita PENDING de 100.000 que bajó de la sincronización.
  Future<void> seedAppointment({String status = 'PENDING'}) =>
      DocumentStore.put(db, SharedDocs.appointments, 'a1', {
        'id': 'a1',
        'professionalId': 'pro-1',
        'client': {'id': 'cli-1', 'name': 'Ana'},
        'date': '2026-11-03T10:00:00.000-05:00',
        'status': status,
        'payment_status': 'PENDING',
        'total_price': '100000.00',
        'services': [],
      });

  setUp(() async {
    databases = memoryDatabases();
    ids = 0;
    repository = PaymentRepositoryImpl(
        OfflineStore(databases: databases, newId: () => 'p-${++ids}'));
    db = await databases.require();
  });

  tearDown(() => databases.close());

  Future<Map<String, dynamic>> appointment() async =>
      (await DocumentStore.get(db, 'appointments', 'a1'))!;

  group('registrar un pago (local + bandeja)', () {
    setUp(seedAppointment);

    test('anticipo: payment.create, la cita pasa a CONFIRMED y PARTIAL',
        () async {
      final payment = (await repository.createPayment(newPayment))
          .getOrElse(() => throw StateError('Left'));
      expect(payment.id, 'p-1');
      expect(payment.status, PaymentStatus.COMPLETED);
      expect(payment.appointmentId, 'a1');
      final entry = (await OutboxStore.all(db)).single;
      expect(entry.type, 'payment.create');
      expect(entry.payload,
          {'appointment_id': 'a1', 'amount': 50000.0, 'payment_method': 'CASH'});
      expect((await appointment())['status'], 'CONFIRMED');
      expect((await appointment())['payment_status'], 'PARTIAL');
    });

    test('el resto: COMPLETED; otro pago más → ya pagada', () async {
      await repository.createPayment(newPayment);
      await repository.createPayment(newPayment);
      expect((await appointment())['payment_status'], 'COMPLETED');
      final failure = leftOf(await repository.createPayment(newPayment));
      expect(failure, isA<ConflictFailure>());
      expect(failure!.code, ApiErrorCode.paymentAlreadyExists);
    });

    test('más que el saldo → ValidationFailure; cita cancelada → no pagable',
        () async {
      expect(
          leftOf(await repository
              .createPayment(newPayment.copyWith(amount: 100000.01))),
          isA<ValidationFailure>());
      await seedAppointment(status: 'CANCELLED');
      expect(leftOf(await repository.createPayment(newPayment)),
          isA<AppointmentNotPayableFailure>());
      expect(await OutboxStore.all(db), isEmpty);
    });

    test('cita que no está en local → NotFoundFailure', () async {
      expect(
          leftOf(await repository
              .createPayment(newPayment.copyWith(appointmentId: 'otra'))),
          isA<NotFoundFailure>());
    });

    test('vuelve con reviewRequired (conflict + saved): sale de la bandeja y '
        'la bajada lo trae en revisión, sin contar para el saldo', () async {
      final server = FakeSyncServer();
      server.forced['payment.create'] = (mid) => MutationResult(
          mutationId: mid,
          status: MutationStatus.conflict,
          code: 'OVERPAID',
          saved: true,
          message: 'El pago quedó en revisión');
      final engine = SyncEngine(
          databases: databases,
          api: server,
          handlers: PaymentsSync.handlers());
      await repository.createPayment(newPayment);
      await engine.syncNow();
      expect(await OutboxStore.all(db), isEmpty);

      // La bajada trae el pago guardado en revisión.
      final payment = (await DocumentStore.get(db, 'payments', 'p-1'))!;
      await PaymentsSync.handlers().first.upsert(db, 'p-1',
          {...payment, 'reviewRequired': 'OVERPAID'});
      final saved = (await repository.getAppointmentPayments('a1'))
          .getOrElse(() => throw StateError('Left'))
          .single;
      expect(saved.reviewRequired, 'OVERPAID');
      expect(saved.needsReview, true);
      final balance = (await GetAppointmentBalanceUseCase(repository)(
              const AppointmentBalanceParams(appointmentId: 'a1', total: 100000)))
          .getOrElse(() => throw StateError('Left'));
      expect(balance.paid, 0, reason: 'en revisión no cuenta');
      await engine.dispose();
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


  group('cobertura recuperada y reembolsos (10.02b/10.03, local)', () {
    setUp(seedAppointment);

    test('pago rechazado por el servidor (403 de una empleada): queda en la '
        'bandeja con el motivo y la cita vuelve a la del servidor', () async {
      final server = FakeSyncServer()
        ..forced['payment.create'] = (mid) => MutationResult(
            mutationId: mid,
            status: MutationStatus.rejected,
            code: 'FORBIDDEN',
            message: 'Solo el dueño registra pagos');
      final engine = SyncEngine(
          databases: databases,
          api: server,
          handlers: [
            ...PaymentsSync.handlers(),
            ...AppointmentsSync.handlers(),
          ]);
      await repository.createPayment(newPayment);
      await engine.syncNow();
      final entry = (await OutboxStore.all(db)).single;
      expect(entry.status, OutboxStatus.rejected);
      expect(entry.message, 'Solo el dueño registra pagos');
      expect(await DocumentStore.get(db, 'payments', 'p-1'), isNull,
          reason: 'el alta rechazada desaparece de local');
      await engine.dispose();
    });

    test('reembolso parcial: el pago sigue COMPLETED y la cita PARTIAL; total: '
        'REFUNDED y la cita REFUNDED (como el backend)', () async {
      final paid = (await repository
              .createPayment(newPayment.copyWith(amount: 100000)))
          .getOrElse(() => throw StateError('pago'));
      expect((await appointment())['payment_status'], 'COMPLETED');

      final partial = (await repository.refundPayment(paid.id!,
              amount: 30000, reason: 'Ajuste'))
          .getOrElse(() => throw StateError('reembolso'));
      expect(partial.status, PaymentStatus.COMPLETED);
      expect(partial.refundAmount, 30000);
      expect((await appointment())['payment_status'], 'PARTIAL');
      expect((await appointment())['status'], 'CONFIRMED',
          reason: 'un reembolso no cambia el estado de la cita');

      final full = (await repository.refundPayment(paid.id!,
              amount: 70000, reason: 'Ajuste'))
          .getOrElse(() => throw StateError('reembolso'));
      expect(full.status, PaymentStatus.REFUNDED);
      expect((await appointment())['payment_status'], 'REFUNDED');
      final entries = await OutboxStore.all(db);
      expect(entries.map((e) => e.type),
          ['payment.create', 'payment.refund', 'payment.refund']);
      expect(entries[1].payload,
          {'refund_amount': 30000.0, 'refund_reason': 'Ajuste'});
    });

    test('pago en revisión: aparece en "por revisar" con el reembolso sugerido '
        'y sale de la revisión al devolver lo que sobra', () async {
      await DocumentStore.put(db, PaymentsSync.payments, 'p-ok', {
        ...backendPayment(),
        'id': 'p-ok',
        'appointment': 'a1',
        'amount': '80000.00',
      });
      await DocumentStore.put(db, PaymentsSync.payments, 'p-rev', {
        ...backendPayment(),
        'id': 'p-rev',
        'appointment': 'a1',
        'amount': '50000.00',
        'reviewRequired': 'OVERPAID',
      });
      final review = (await GetPaymentsInReviewUseCase(repository)(NoParams()))
          .getOrElse(() => throw StateError('revisión'))
          .single;
      expect(review.payment.id, 'p-rev');
      expect(review.suggestedRefund, 30000);
      expect(review.clientName, 'Ana');

      await repository.refundPayment('p-rev', amount: 30000, reason: 'De más');
      final resolved = PaymentModel.fromJson(
              (await DocumentStore.get(db, 'payments', 'p-rev'))!)
          .toEntity();
      expect(resolved.needsReview, false);
      expect((await appointment())['payment_status'], 'COMPLETED');
    });

    test('reembolso de un pago que no está en local → NotFoundFailure',
        () async {
      expect(
          leftOf(await repository.refundPayment('nada',
              amount: 1, reason: 'x')),
          isA<NotFoundFailure>());
    });

    test('sin métodos propios (o Employee, que no los recibe) → Right([])',
        () async {
      expect(
          (await repository.getActiveCustomPaymentMethods())
              .getOrElse(() => throw StateError('L')),
          isEmpty);
    });

    test('saldo: pagada de más → saldo 0', () async {
      for (var i = 0; i < 3; i++) {
        await DocumentStore.put(db, PaymentsSync.payments, 'x$i',
            {...backendPayment(), 'id': 'x$i', 'appointment': 'a1'});
      }
      final full = (await GetAppointmentBalanceUseCase(repository)(
              const AppointmentBalanceParams(appointmentId: 'a1', total: 100000)))
          .getOrElse(() => throw StateError('L'));
      expect(full.outstanding, 0);
      expect(full.isFullyPaid, true);
    });
  });

  group('métodos propios (locales)', () {
    test('solo los activos, por nombre', () async {
      await DocumentStore.put(db, PaymentsSync.customMethods, 'cm-2',
          {...backendCustomMethod, 'id': 'cm-2', 'name': 'Daviplata'});
      await DocumentStore.put(
          db, PaymentsSync.customMethods, 'cm-1', backendCustomMethod);
      await DocumentStore.put(db, PaymentsSync.customMethods, 'cm-3',
          {...backendCustomMethod, 'id': 'cm-3', 'isActive': false});
      final methods = (await GetActiveCustomPaymentMethodsUseCase(repository)(
              NoParams()))
          .getOrElse(() => throw StateError('Left'));
      expect(methods.map((m) => m.name), ['Daviplata', 'Nequi']);
    });
  });

  group('saldo de una cita (anticipos, 2.24)', () {
    const params = AppointmentBalanceParams(appointmentId: 'a1', total: 100000);

    test('solo COMPLETED, netos de reembolsos (pagos del feed)', () async {
      for (final (i, json) in [
        backendPayment(), // 50.000 pagados
        backendPayment(refund: '10000.00'), // 50.000 − 10.000
        backendPayment(status: 'REFUNDED', refund: '50000.00'),
        backendPayment(status: 'FAILED'),
      ].indexed) {
        await DocumentStore.put(db, PaymentsSync.payments, 'p$i',
            {...json, 'id': 'p$i', 'appointment': 'a1'});
      }
      final result = (await GetAppointmentBalanceUseCase(repository)(params))
          .getOrElse(() => throw StateError('Left'));
      expect(result, const AppointmentBalance(total: 100000, paid: 90000));
      expect(result.outstanding, 10000);
    });

    test('sin pagos → falta el total', () async {
      expect(
          (await GetAppointmentBalanceUseCase(repository)(params))
              .getOrElse(() => throw StateError('L')),
          const AppointmentBalance(total: 100000, paid: 0));
    });
  });

  group('pagos en revisión y reembolso (10.03)', () {
    Future<void> seedReview(String id, String reason,
        {String amount = '60000.00', String appointmentStatus = 'CONFIRMED'}) async {
      await seedAppointment(status: appointmentStatus);
      await DocumentStore.put(db, PaymentsSync.payments, id, {
        'id': id,
        'appointment': 'a1',
        'amount': amount,
        'payment_method': 'CASH',
        'status': 'COMPLETED',
        'refund_amount': null,
        'reviewRequired': reason,
        'created_at': '2026-11-03T15:00:00.000Z',
      });
    }

    test('lista los pagos en revisión con su cita y lo que hay que devolver',
        () async {
      await seedReview('pr', 'OVERPAID');
      await DocumentStore.put(db, PaymentsSync.payments, 'ok', {
        'id': 'ok',
        'appointment': 'a1',
        'amount': '70000.00',
        'payment_method': 'CASH',
        'status': 'COMPLETED',
        'created_at': '2026-11-03T14:00:00.000Z',
      });
      final items = (await repository.getPaymentsInReview())
          .getOrElse(() => throw StateError('Left'));
      final item = items.single;
      expect(item.payment.id, 'pr');
      expect(item.clientName, 'Ana');
      expect(item.appointmentTotal, 100000);
      // 70.000 ya pagados + 60.000 = 130.000: sobran 30.000.
      expect(item.suggestedRefund, 30000);
      expect(item.isForCancelledAppointment, isFalse);
    });

    test('reembolso de lo que sobra: sale de revisión y va a la bandeja',
        () async {
      await seedReview('pr', 'OVERPAID');
      await DocumentStore.put(db, PaymentsSync.payments, 'ok', {
        'id': 'ok',
        'appointment': 'a1',
        'amount': '70000.00',
        'payment_method': 'CASH',
        'status': 'COMPLETED',
        'created_at': '2026-11-03T14:00:00.000Z',
      });
      final refunded = (await RefundPaymentUseCase(repository)(
              RefundPaymentParams(
                  payment: (await repository.getPaymentsInReview())
                      .getOrElse(() => throw StateError('L'))
                      .single
                      .payment,
                  amount: 30000,
                  reason: 'Pago de más')))
          .getOrElse(() => throw StateError('Left'));
      expect(refunded.refundAmount, 30000);
      expect(refunded.needsReview, isFalse);
      expect(refunded.status, PaymentStatus.COMPLETED);
      final entry = (await OutboxStore.all(db)).single;
      expect(entry.type, 'payment.refund');
      expect(entry.payload, {'refund_amount': 30000.0, 'refund_reason': 'Pago de más'});
      expect((await appointment())['payment_status'], 'COMPLETED');
    });

    test('cita cancelada: devolver todo lo deja REFUNDED y fuera de revisión',
        () async {
      await seedReview('pr', 'APPOINTMENT_CANCELLED',
          appointmentStatus: 'CANCELLED');
      final item = (await repository.getPaymentsInReview())
          .getOrElse(() => throw StateError('L'))
          .single;
      expect(item.suggestedRefund, 60000);
      final partial = (await RefundPaymentUseCase(repository)(RefundPaymentParams(
              payment: item.payment, amount: 10000, reason: 'Parcial')))
          .getOrElse(() => throw StateError('Left'));
      expect(partial.needsReview, isTrue, reason: 'aún no cabe');
      final rest = (await RefundPaymentUseCase(repository)(RefundPaymentParams(
              payment: partial, amount: 50000, reason: 'Cita cancelada')))
          .getOrElse(() => throw StateError('Left'));
      expect(rest.status, PaymentStatus.REFUNDED);
      expect(rest.needsReview, isFalse);
    });

    test('monto inválido o sin motivo: no llega al repositorio', () async {
      await seedReview('pr', 'OVERPAID');
      final payment = (await repository.getPaymentsInReview())
          .getOrElse(() => throw StateError('L'))
          .single
          .payment;
      for (final (amount, reason) in [(0.0, 'x'), (70000.0, 'x'), (100.0, ' ')]) {
        expect(
            leftOf(await RefundPaymentUseCase(repository)(RefundPaymentParams(
                payment: payment, amount: amount, reason: reason))),
            isA<ValidationFailure>());
      }
      expect(await OutboxStore.all(db), isEmpty);
    });
  });
}
