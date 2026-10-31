import 'package:login_signup/core/database/app_database.dart';
import 'package:login_signup/core/database/document_store.dart';
import 'package:login_signup/core/database/shared_documents.dart';
import 'package:login_signup/core/sync/document_sync_handler.dart';
import 'package:login_signup/core/sync/outbox_store.dart';
import 'package:login_signup/core/utils/business_time_zone.dart';
import 'package:login_signup/core/utils/json_read.dart';

/// Pagos sin conexión (10.02b, solo Owner): `payment.create` y cómo se
/// aplica en local, incluido el efecto en la cita (el primer pago la
/// confirma; su estado de pago pasa a parcial o pagada), con las mismas
/// cuentas que el backend (`payment-rules.ts`: pagos `COMPLETED` netos, en
/// centavos; los que están en revisión no cuentan).
abstract final class PaymentsSync {
  static const create = 'payment.create';

  /// Reembolso (10.03): `{refund_amount, refund_reason}` sobre el pago.
  static const refund = 'payment.refund';

  /// Motivos de revisión (backend `PAYMENT_REVIEW`).
  static const reviewCancelled = 'APPOINTMENT_CANCELLED';
  static const reviewOverpaid = 'OVERPAID';

  static final payments = DocumentKind('payments',
      ref1: (d) => appointmentIdOf(d), at: (d) => d['created_at']);
  static const customMethods = DocumentKind('custom_payment_methods');

  static String? appointmentIdOf(Map<String, dynamic> payment) =>
      JsonRead.asOptionalString(payment['appointment_id']) ??
      (payment['appointment'] is Map
          ? JsonRead.asOptionalString((payment['appointment'] as Map)['id'])
          : JsonRead.asOptionalString(payment['appointment']));

  static Future<void> apply(AppDatabase db, OutboxEntry entry) async {
    if (entry.type == refund) return applyRefund(db, entry);
    final id = entry.entityId;
    if (id == null || entry.type != create) return;
    final p = entry.payload;
    final appointmentId = JsonRead.asString(p['appointment_id']);
    await DocumentStore.keepServerCopy(db, payments.entity, id);
    await DocumentStore.put(db, payments, id, {
      'id': id,
      'appointment': appointmentId,
      'amount': JsonRead.asDouble(p['amount']).toStringAsFixed(2),
      'payment_method': p['payment_method'],
      'custom_payment_method_id': p['custom_payment_method_id'],
      'status': 'COMPLETED',
      'transaction_id': p['transaction_id'],
      'refund_amount': null,
      'refund_reason': null,
      'timezone': BusinessTimeZone.current,
      'reviewRequired': null,
      'created_at': entry.clientTime,
      'updated_at': entry.clientTime,
    });
    await refreshAppointment(db, appointmentId);
  }

  /// Reembolso en local, con las cuentas del backend (`applyRefund` y la
  /// resolución de la revisión de `PaymentsService.refund`): se acumula; el
  /// pago pasa a `REFUNDED` cuando se devuelve todo; uno en revisión deja de
  /// estarlo cuando ya cabe (cita cancelada: devuelto entero; de más: lo
  /// pagado de la cita con él no pasa del total).
  static Future<void> applyRefund(AppDatabase db, OutboxEntry entry) async {
    final id = entry.entityId;
    if (id == null) return;
    final payment = await DocumentStore.get(db, payments.entity, id);
    if (payment == null) return;
    final amountCents = (JsonRead.asDouble(payment['amount']) * 100).round();
    final refundedCents =
        (JsonRead.asDouble(payment['refund_amount']) * 100).round() +
            (JsonRead.asDouble(entry.payload['refund_amount']) * 100).round();
    final appointmentId = appointmentIdOf(payment);
    var review = JsonRead.asOptionalString(payment['reviewRequired']);
    if (review != null && appointmentId != null) {
      final net = amountCents - refundedCents;
      if (review == reviewCancelled) {
        if (net <= 0) review = null;
      } else {
        final appointment = await DocumentStore.get(
            db, SharedDocs.appointments.entity, appointmentId);
        final total =
            (JsonRead.asDouble(appointment?['total_price']) * 100).round();
        if (await paidCents(db, appointmentId) + net <= total) review = null;
      }
    }
    await DocumentStore.keepServerCopy(db, payments.entity, id);
    await DocumentStore.merge(db, payments, id, {
      'refund_amount': (refundedCents / 100).toStringAsFixed(2),
      'refund_reason': entry.payload['refund_reason'],
      'status': refundedCents >= amountCents ? 'REFUNDED' : payment['status'],
      'reviewRequired': review,
      'updated_at': entry.clientTime,
    });
    if (appointmentId != null) await refreshAppointment(db, appointmentId);
  }

  /// Pagado neto (centavos) de una cita según los pagos locales.
  static Future<int> paidCents(AppDatabase db, String appointmentId) async {
    var cents = 0;
    for (final payment
        in await DocumentStore.list(db, payments.entity, ref1: appointmentId)) {
      if (payment['status'] != 'COMPLETED') continue;
      if (JsonRead.asOptionalString(payment['reviewRequired']) != null) {
        continue;
      }
      cents += (JsonRead.asDouble(payment['amount']) * 100).round() -
          (JsonRead.asDouble(payment['refund_amount']) * 100).round();
    }
    return cents;
  }

  /// Estado y estado de pago de la cita tras un pago (`statusAfterPayment` y
  /// `appointmentPaymentStatus` del backend).
  static Future<void> refreshAppointment(
      AppDatabase db, String appointmentId) async {
    final kind = SharedDocs.appointments;
    final appointment = await DocumentStore.get(db, kind.entity, appointmentId);
    if (appointment == null) return;
    final total = (JsonRead.asDouble(appointment['total_price']) * 100).round();
    final paid = await paidCents(db, appointmentId);
    final paymentStatus = paid <= 0
        ? appointment['payment_status']
        : paid >= total
            ? 'COMPLETED'
            : 'PARTIAL';
    await DocumentStore.keepServerCopy(db, kind.entity, appointmentId);
    await DocumentStore.merge(db, kind, appointmentId, {
      'payment_status': paymentStatus,
      if (appointment['status'] == 'PENDING' && paid > 0) 'status': 'CONFIRMED',
    });
  }

  static List<DocumentSyncHandler> handlers() => [
        DocumentSyncHandler(payments, applyLocal: apply),
        DocumentSyncHandler(customMethods),
      ];
}
