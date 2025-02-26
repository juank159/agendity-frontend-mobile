class PaymentMethodStatsEntity {
  final String method;
  final String methodType; // 'STANDARD' o 'CUSTOM'
  final int count;
  final double total;
  final double average;
  final double percentage;

  PaymentMethodStatsEntity({
    required this.method,
    required this.methodType,
    required this.count,
    required this.total,
    required this.average,
    required this.percentage,
  });
}
