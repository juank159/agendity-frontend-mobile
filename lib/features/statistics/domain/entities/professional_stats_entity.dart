class ProfessionalStatsEntity {
  final String professionalId;
  final String professionalName;
  final int appointmentCount;
  final int paymentCount;
  final double totalAmount;
  final double averagePerPayment;
  final double percentageOfTotal;

  ProfessionalStatsEntity({
    required this.professionalId,
    required this.professionalName,
    required this.appointmentCount,
    required this.paymentCount,
    required this.totalAmount,
    required this.averagePerPayment,
    required this.percentageOfTotal,
  });
}
