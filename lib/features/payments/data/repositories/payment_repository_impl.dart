import 'package:dartz/dartz.dart';
import 'package:login_signup/core/database/document_store.dart';
import 'package:login_signup/core/database/shared_documents.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/network/safe_call.dart';
import 'package:login_signup/core/sync/offline_store.dart';
import 'package:login_signup/core/utils/date_codec.dart';
import 'package:login_signup/core/utils/json_read.dart';
import 'package:login_signup/features/payments/data/models/custom_payment_method_model.dart';
import 'package:login_signup/features/payments/data/models/payment_model.dart';
import 'package:login_signup/features/payments/data/sync/payments_sync.dart';
import 'package:login_signup/features/payments/domain/entities/custom_payment_method.dart';
import 'package:login_signup/features/payments/domain/entities/payment_entity.dart';
import 'package:login_signup/features/payments/domain/entities/payment_review_item.dart';
import 'package:login_signup/features/payments/domain/failures/payment_failures.dart';
import 'package:login_signup/features/payments/domain/repositories/payment_repository.dart';

/// Pagos sin conexión (10.02b, D-18; solo Owner: el Employee no los recibe
/// en la sincronización). Registrar un pago lo guarda en local + bandeja
/// (`payment.create`) y actualiza la cita como lo haría el servidor. Lo que
/// se ve en local se avisa al momento (cita cancelada, pasarse del saldo); si
/// al sincronizar el servidor ve otra cosa (otro dispositivo cobró o
/// canceló), el pago **se guarda en revisión** (`reviewRequired`): el dinero
/// ya se recibió.
class PaymentRepositoryImpl implements PaymentRepository {
  final OfflineStore _store;

  PaymentRepositoryImpl(this._store);

  static const _entity = 'payments';

  @override
  Future<Either<Failure, PaymentEntity>> createPayment(PaymentEntity payment) =>
      OfflineStore.guard(() async {
        final db = await _store.database();
        final appointment = await DocumentStore.get(
            db, SharedDocs.appointments.entity, payment.appointmentId);
        if (appointment == null) return const Left(NotFoundFailure());
        if (appointment['status'] == 'CANCELLED') {
          return const Left(AppointmentNotPayableFailure());
        }
        final total =
            (JsonRead.asDouble(appointment['total_price']) * 100).round();
        final paid = await PaymentsSync.paidCents(db, payment.appointmentId);
        if (paid >= total) {
          return const Left(ConflictFailure(
              message: 'La cita ya está pagada por completo',
              code: ApiErrorCode.paymentAlreadyExists));
        }
        if ((payment.amount * 100).round() > total - paid) {
          return const Left(ValidationFailure(
              message: 'El monto supera el saldo pendiente de la cita'));
        }
        final id = _store.newId();
        await _store.write((db, sink) async {
          final entry = await sink.add(
              type: PaymentsSync.create,
              entity: _entity,
              entityId: id,
              payload: PaymentModel.fromEntity(payment).toJson());
          await PaymentsSync.apply(db, entry);
        });
        final saved = await DocumentStore.get(db, _entity, id);
        return Right(PaymentModel.fromJson(saved!).toEntity());
      });

  @override
  Future<Either<Failure, List<PaymentReviewItem>>> getPaymentsInReview() =>
      safeCall(() async {
        final db = await _store.database();
        final items = <PaymentReviewItem>[];
        for (final doc in await DocumentStore.list(db, _entity)) {
          final payment = PaymentModel.fromJson(doc).toEntity();
          if (!payment.needsReview) continue;
          final appointment = await DocumentStore.get(
              db, SharedDocs.appointments.entity, payment.appointmentId);
          final total = JsonRead.asDouble(appointment?['total_price']);
          final cancelled = payment.reviewRequired ==
              PaymentReviewReason.appointmentCancelled;
          final others = (await PaymentsSync.paidCents(
                  db, payment.appointmentId)) /
              100;
          final excess = others + payment.netAmount - total;
          items.add(PaymentReviewItem(
            payment: payment,
            clientName: _clientName(appointment),
            appointmentDate: DateCodec.tryDecode(appointment?['date'],
                timeZone: JsonRead.asOptionalString(appointment?['timezone'])),
            appointmentTotal: total,
            suggestedRefund: cancelled
                ? payment.netAmount
                : excess.clamp(0, payment.netAmount).toDouble(),
          ));
        }
        return items;
      });

  static String _clientName(Map<String, dynamic>? appointment) {
    final client = JsonRead.asMap(appointment?['client']);
    final name = '${JsonRead.asString(client?['name'])} '
            '${JsonRead.asString(client?['lastname'])}'
        .trim();
    return name.isEmpty ? 'Cliente' : name;
  }

  @override
  Future<Either<Failure, PaymentEntity>> refundPayment(String paymentId,
          {required double amount, required String reason}) =>
      OfflineStore.guard(() async {
        final db = await _store.database();
        if (await DocumentStore.get(db, _entity, paymentId) == null) {
          return const Left(NotFoundFailure());
        }
        await _store.write((db, sink) async {
          final entry = await sink.add(
              type: PaymentsSync.refund,
              entity: _entity,
              entityId: paymentId,
              payload: {'refund_amount': amount, 'refund_reason': reason});
          await PaymentsSync.apply(db, entry);
        });
        final saved = await DocumentStore.get(db, _entity, paymentId);
        return Right(PaymentModel.fromJson(saved!).toEntity());
      });

  @override
  Future<Either<Failure, List<CustomPaymentMethod>>>
      getActiveCustomPaymentMethods() => safeCall(() async {
            final docs = await DocumentStore.list(
                await _store.database(), PaymentsSync.customMethods.entity);
            return [
              for (final doc in docs)
                if (JsonRead.asBool(doc['isActive'], fallback: true))
                  CustomPaymentMethodModel.fromJson(doc).toEntity(),
            ]..sort((a, b) =>
                a.name.toLowerCase().compareTo(b.name.toLowerCase()));
          });

  @override
  Future<Either<Failure, List<PaymentEntity>>> getAppointmentPayments(
          String appointmentId) =>
      safeCall(() async => [
            for (final doc in await DocumentStore.list(
                await _store.database(), _entity,
                ref1: appointmentId))
              PaymentModel.fromJson(doc).toEntity(),
          ]);
}
