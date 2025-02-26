// lib/common/enums/payment_method_enum.dart
enum PaymentMethod { CASH, CREDIT_CARD, DEBIT_CARD, TRANSFER, ONLINE, CUSTOM }

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
