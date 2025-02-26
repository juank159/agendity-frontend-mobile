class ServiceStatsEntity {
  final String serviceId;
  final String serviceName;
  final int paymentCount;
  final double totalAmount;
  final double averageAmount;
  final double percentageOfTotal;

  ServiceStatsEntity({
    required this.serviceId,
    required this.serviceName,
    required this.paymentCount,
    required this.totalAmount,
    required this.averageAmount,
    required this.percentageOfTotal,
  });
}
