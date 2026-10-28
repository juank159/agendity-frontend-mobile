/// Resumen de ingresos de un período (`GET /payments/stats`).
///
/// Ingresos **netos**: suma de los pagos `COMPLETED` menos lo reembolsado
/// (`amount - refund_amount`). Sin pagos en el rango, todo en 0.
class PaymentStatsEntity {
  final double totalAmount;
  final int paymentCount;
  final double averageAmount;

  const PaymentStatsEntity({
    required this.totalAmount,
    required this.paymentCount,
    required this.averageAmount,
  });

  static const empty =
      PaymentStatsEntity(totalAmount: 0, paymentCount: 0, averageAmount: 0);

  bool get isEmpty => paymentCount == 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaymentStatsEntity &&
          other.totalAmount == totalAmount &&
          other.paymentCount == paymentCount &&
          other.averageAmount == averageAmount;

  @override
  int get hashCode => Object.hash(totalAmount, paymentCount, averageAmount);
}
