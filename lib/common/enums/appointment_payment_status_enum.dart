/// Estado de pago de una CITA (`appointments.payment_status`). Valores
/// idénticos a `AppointmentPaymentStatus` del backend
/// (`backend/src/common/enums/status.enum.ts`, 2.24). Lo calcula el backend
/// con lo pagado neto: `PENDING` (nada) → `PARTIAL` (anticipo) → `COMPLETED`
/// (el total); `REFUNDED` = se devolvió todo. `FAILED` y `CANCELLED` existen
/// en la columna pero el backend no los asigna.
///
/// No confundir con `PaymentStatus`, el estado de UN pago (sin `PARTIAL`).
enum AppointmentPaymentStatus {
  PENDING,
  PARTIAL,
  COMPLETED,
  FAILED,
  REFUNDED,
  CANCELLED;

  String toApi() => name;

  /// Tolerante: ignora mayúsculas/espacios y acepta `CANCELED`. `null` si el
  /// valor falta o no se reconoce (el llamador decide el valor por defecto).
  static AppointmentPaymentStatus? fromApi(Object? value) {
    if (value is! String) return null;
    final normalized = value.trim().toUpperCase();
    if (normalized == 'CANCELED') return AppointmentPaymentStatus.CANCELLED;
    for (final status in values) {
      if (status.name == normalized) return status;
    }
    return null;
  }

  /// Queda algo pagado sin reembolsar: la cita no se puede cancelar
  /// (`APPOINTMENT_PAID`) hasta reembolsarlo.
  bool get hasNetPayments =>
      this == AppointmentPaymentStatus.PARTIAL ||
      this == AppointmentPaymentStatus.COMPLETED;

  /// Pagada del todo: no admite más pagos (`PAYMENT_ALREADY_EXISTS`).
  bool get isFullyPaid => this == AppointmentPaymentStatus.COMPLETED;
}
