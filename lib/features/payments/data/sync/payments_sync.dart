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

  static final payments = DocumentKind('payments',
      ref1: (d) => appointmentIdOf(d), at: (d) => d['created_at']);
  static const customMethods = DocumentKind('custom_payment_methods');

  static String? appointmentIdOf(Map<String, dynamic> payment) =>
      JsonRead.asOptionalString(payment['appointment_id']) ??
      (payment['appointment'] is Map
          ? JsonRead.asOptionalString((payment['appointment'] as Map)['id'])
          : JsonRead.asOptionalString(payment['appointment']));

  static Future<void> apply(AppDatabase db, OutboxEntry entry) async {
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
