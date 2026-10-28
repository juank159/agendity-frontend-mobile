import 'package:login_signup/common/enums/payment_method_enum.dart';

/// Origen del método en `GET /payments/stats/by-method`.
enum PaymentMethodType {
  standard,
  custom;

  /// `'CUSTOM'` → [custom]; cualquier otro valor (o ninguno) → [standard].
  static PaymentMethodType fromApi(Object? value) =>
      value?.toString().trim().toUpperCase() == 'CUSTOM' ? custom : standard;
}

/// Ingresos netos agrupados por método de pago.
class PaymentMethodStatsEntity {
  /// Código tal como llega (`CASH`, `TRANSFER`…); sirve de etiqueta si
  /// [paymentMethod] es `null` (método que la app no conoce).
  final String method;

  /// [method] como enum; `null` si no es un método estándar.
  final PaymentMethod? paymentMethod;
  final PaymentMethodType methodType;
  final int count;
  final double total;
  final double average;

  /// Porcentaje (0–100) sobre los ingresos netos del período.
  final double percentage;

  const PaymentMethodStatsEntity({
    required this.method,
    this.paymentMethod,
    this.methodType = PaymentMethodType.standard,
    required this.count,
    required this.total,
    required this.average,
    required this.percentage,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaymentMethodStatsEntity &&
          other.method == method &&
          other.paymentMethod == paymentMethod &&
          other.methodType == methodType &&
          other.count == count &&
          other.total == total &&
          other.average == average &&
          other.percentage == percentage;

  @override
  int get hashCode => Object.hash(
      method, paymentMethod, methodType, count, total, average, percentage);
}
