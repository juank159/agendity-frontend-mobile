/// Método de pago. Los estándar son idénticos a `PaymentMethod` del backend.
/// `CUSTOM` es solo de la app: un método propio del negocio, que viaja como
/// `custom_payment_method_id` (el backend no tiene el valor `CUSTOM`).
enum PaymentMethod {
  CASH,
  CREDIT_CARD,
  DEBIT_CARD,
  TRANSFER,
  ONLINE,
  CUSTOM;

  /// Valor de `payment_method` para el backend; `null` para `CUSTOM`.
  String? toApi() => this == PaymentMethod.CUSTOM ? null : name;

  /// Tolerante: ignora mayúsculas, espacios y guiones (`credit-card`).
  /// `null` si el valor falta o no es un método estándar.
  static PaymentMethod? fromApi(Object? value) {
    if (value is! String) return null;
    final normalized =
        value.trim().toUpperCase().replaceAll(RegExp(r'[\s-]+'), '_');
    for (final method in values) {
      if (method != PaymentMethod.CUSTOM && method.name == normalized) {
        return method;
      }
    }
    return null;
  }
}

extension PaymentMethodExtension on PaymentMethod {
  String get displayName {
    switch (this) {
      case PaymentMethod.CASH:
        return 'Efectivo';
      case PaymentMethod.CREDIT_CARD:
        return 'Tarjeta de crédito';
      case PaymentMethod.DEBIT_CARD:
        return 'Tarjeta de débito';
      case PaymentMethod.TRANSFER:
        return 'Transferencia';
      case PaymentMethod.ONLINE:
        return 'Pago en línea';
      case PaymentMethod.CUSTOM:
        return 'Otro método';
    }
  }
}
