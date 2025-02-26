class ClientStatsEntity {
  final String clientId;
  final String clientName;
  final DateTime firstVisitDate;
  final DateTime lastVisitDate;
  final int visitCount;
  final int paymentCount;
  final double totalSpent;
  final double averagePerPayment;
  final int frequencyDays;

  ClientStatsEntity({
    required this.clientId,
    required this.clientName,
    required this.firstVisitDate,
    required this.lastVisitDate,
    required this.visitCount,
    required this.paymentCount,
    required this.totalSpent,
    required this.averagePerPayment,
    required this.frequencyDays,
  });
}
