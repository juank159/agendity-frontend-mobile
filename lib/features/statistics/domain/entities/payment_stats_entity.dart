class PaymentStatsEntity {
  final double totalAmount;
  final int paymentCount;
  final double averageAmount;

  PaymentStatsEntity({
    required this.totalAmount,
    required this.paymentCount,
    required this.averageAmount,
  });
}
