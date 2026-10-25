import 'package:login_signup/common/enums/payment_method_enum.dart';
import 'package:login_signup/common/enums/payment_status_enum.dart';

/// Pago de una cita (backend: `payments`). Una cita admite un solo pago
/// `COMPLETED`; los reembolsos se acumulan en [refundAmount] y el pago pasa a
/// `REFUNDED` solo cuando se devuelve todo.
class PaymentEntity {
  /// `null` mientras no lo haya creado el backend.
  final String? id;
  final String appointmentId;

  /// Importe en COP (> 0 y ≤ total de la cita).
  final double amount;

  /// `CUSTOM` = método propio del negocio, identificado por
  /// [customPaymentMethodId].
  final PaymentMethod paymentMethod;
  final String? customPaymentMethodId;
  final PaymentStatus status;
  final String? transactionId;

  /// Acumulado de reembolsos (0 si no hubo).
  final double refundAmount;
  final String? refundReason;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const PaymentEntity({
    this.id,
    required this.appointmentId,
    required this.amount,
    required this.paymentMethod,
    this.customPaymentMethodId,
    this.status = PaymentStatus.PENDING,
    this.transactionId,
    this.refundAmount = 0,
    this.refundReason,
    this.createdAt,
    this.updatedAt,
  });

  /// Lo que cuenta como ingreso (igual que las estadísticas del backend).
  double get netAmount => amount - refundAmount;

  PaymentEntity copyWith({
    String? id,
    String? appointmentId,
    double? amount,
    PaymentMethod? paymentMethod,
    String? customPaymentMethodId,
    PaymentStatus? status,
    String? transactionId,
    double? refundAmount,
    String? refundReason,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      PaymentEntity(
        id: id ?? this.id,
        appointmentId: appointmentId ?? this.appointmentId,
        amount: amount ?? this.amount,
        paymentMethod: paymentMethod ?? this.paymentMethod,
        customPaymentMethodId:
            customPaymentMethodId ?? this.customPaymentMethodId,
        status: status ?? this.status,
        transactionId: transactionId ?? this.transactionId,
        refundAmount: refundAmount ?? this.refundAmount,
        refundReason: refundReason ?? this.refundReason,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaymentEntity &&
          other.id == id &&
          other.appointmentId == appointmentId &&
          other.amount == amount &&
          other.paymentMethod == paymentMethod &&
          other.customPaymentMethodId == customPaymentMethodId &&
          other.status == status &&
          other.transactionId == transactionId &&
          other.refundAmount == refundAmount &&
          other.refundReason == refundReason &&
          other.createdAt == createdAt &&
          other.updatedAt == updatedAt;

  @override
  int get hashCode => Object.hash(
        id,
        appointmentId,
        amount,
        paymentMethod,
        customPaymentMethodId,
        status,
        transactionId,
        refundAmount,
        refundReason,
        createdAt,
        updatedAt,
      );
}
