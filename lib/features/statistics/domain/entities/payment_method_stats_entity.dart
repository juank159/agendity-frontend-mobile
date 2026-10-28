import 'package:login_signup/common/enums/payment_method_enum.dart';

/// Origen del método en `GET /payments/stats/by-method`.
enum PaymentMethodType {
  standard,
  custom;

  /// `'CUSTOM'` → [custom]; cualquier otro valor (o ninguno) → [standard].
  static PaymentMethodType fromApi(Object? value) =>
      value?.toString().trim().toUpperCase() == 'CUSTOM' ? custom : standard;
}

/// Ingresos netos agrupados por método de pago: los estándar y cada método
/// propio del negocio por separado (2.28).
class PaymentMethodStatsEntity {
  /// Código tal como llega (`CASH`, `TRANSFER`…) o, en un método propio, su
  /// nombre; sirve de etiqueta si [paymentMethod] es `null`.
  final String method;

  /// [method] como enum; `null` en los métodos propios y en los que la app no
  /// conoce.
  final PaymentMethod? paymentMethod;
  final PaymentMethodType methodType;

  /// Id del método propio; `null` en los estándar.
  final String? customPaymentMethodId;
  final int count;
  final double total;
  final double average;

  /// Porcentaje (0–100) sobre los ingresos netos del período.
  final double percentage;

  const PaymentMethodStatsEntity({
    required this.method,
    this.paymentMethod,
    this.methodType = PaymentMethodType.standard,
    this.customPaymentMethodId,
    required this.count,
    required this.total,
    required this.average,
    required this.percentage,
  });

  bool get isCustom => methodType == PaymentMethodType.custom;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaymentMethodStatsEntity &&
          other.method == method &&
          other.paymentMethod == paymentMethod &&
          other.methodType == methodType &&
          other.customPaymentMethodId == customPaymentMethodId &&
          other.count == count &&
          other.total == total &&
          other.average == average &&
          other.percentage == percentage;

  @override
  int get hashCode => Object.hash(method, paymentMethod, methodType,
      customPaymentMethodId, count, total, average, percentage);
}
