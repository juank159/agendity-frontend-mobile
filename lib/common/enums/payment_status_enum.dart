/// Estado de un pago. Valores idénticos a `PaymentStatus` del backend; también
/// es el `payment_status` de una cita.
enum PaymentStatus {
  PENDING,
  COMPLETED,
  FAILED,
  REFUNDED,
  CANCELLED;

  String toApi() => name;

  /// Tolerante: ignora mayúsculas/espacios y acepta `CANCELED`. `null` si el
  /// valor falta o no se reconoce.
  static PaymentStatus? fromApi(Object? value) {
    if (value is! String) return null;
    final normalized = value.trim().toUpperCase();
    if (normalized == 'CANCELED') return PaymentStatus.CANCELLED;
    for (final status in values) {
      if (status.name == normalized) return status;
    }
    return null;
  }
}
