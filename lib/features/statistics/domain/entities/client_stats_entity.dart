/// Gasto neto y frecuencia de un cliente (`GET /payments/stats/by-client`),
/// ordenados por gasto.
class ClientStatsEntity {
  final String clientId;
  final String clientName;

  /// Primera y última cita pagada en el rango (instantes, hora local).
  final DateTime? firstVisitDate;
  final DateTime? lastVisitDate;
  final int visitCount;
  final int paymentCount;
  final double totalSpent;
  final double averagePerPayment;

  /// Días promedio entre visitas (0 con una sola visita).
  final int frequencyDays;

  const ClientStatsEntity({
    required this.clientId,
    required this.clientName,
    this.firstVisitDate,
    this.lastVisitDate,
    required this.visitCount,
    required this.paymentCount,
    required this.totalSpent,
    required this.averagePerPayment,
    required this.frequencyDays,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClientStatsEntity &&
          other.clientId == clientId &&
          other.clientName == clientName &&
          other.firstVisitDate == firstVisitDate &&
          other.lastVisitDate == lastVisitDate &&
          other.visitCount == visitCount &&
          other.paymentCount == paymentCount &&
          other.totalSpent == totalSpent &&
          other.averagePerPayment == averagePerPayment &&
          other.frequencyDays == frequencyDays;

  @override
  int get hashCode => Object.hash(
      clientId,
      clientName,
      firstVisitDate,
      lastVisitDate,
      visitCount,
      paymentCount,
      totalSpent,
      averagePerPayment,
      frequencyDays);
}
