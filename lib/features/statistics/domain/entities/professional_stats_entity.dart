/// Ingresos netos por profesional (`GET /payments/stats/by-professional`),
/// ordenados de mayor a menor.
class ProfessionalStatsEntity {
  final String professionalId;
  final String professionalName;
  final int appointmentCount;
  final int paymentCount;
  final double totalAmount;
  final double averagePerPayment;

  /// Porcentaje (0–100) sobre los ingresos netos del período.
  final double percentageOfTotal;

  const ProfessionalStatsEntity({
    required this.professionalId,
    required this.professionalName,
    required this.appointmentCount,
    required this.paymentCount,
    required this.totalAmount,
    required this.averagePerPayment,
    required this.percentageOfTotal,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProfessionalStatsEntity &&
          other.professionalId == professionalId &&
          other.professionalName == professionalName &&
          other.appointmentCount == appointmentCount &&
          other.paymentCount == paymentCount &&
          other.totalAmount == totalAmount &&
          other.averagePerPayment == averagePerPayment &&
          other.percentageOfTotal == percentageOfTotal;

  @override
  int get hashCode => Object.hash(
      professionalId,
      professionalName,
      appointmentCount,
      paymentCount,
      totalAmount,
      averagePerPayment,
      percentageOfTotal);
}
