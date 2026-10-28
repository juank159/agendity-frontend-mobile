/// Ingreso neto por servicio (`GET /payments/stats/by-service`, 2.28).
///
/// Lo pagado neto de cada cita del período se reparte entre sus servicios en
/// proporción al precio de cada uno en la cita: la lista suma el ingreso neto
/// y [percentageOfTotal] suma 100.
class ServiceStatsEntity {
  final String serviceId;
  final String serviceName;

  /// Citas con pagos en el período que incluyen el servicio.
  final int appointmentCount;

  /// Pagos de esas citas (una cita puede tener varios: anticipos).
  final int paymentCount;

  /// Ingreso neto atribuido al servicio.
  final double totalAmount;

  /// Neto por cita: [totalAmount] / [appointmentCount].
  final double averageAmount;

  /// Porcentaje (0–100) del ingreso neto del período.
  final double percentageOfTotal;

  const ServiceStatsEntity({
    required this.serviceId,
    required this.serviceName,
    required this.appointmentCount,
    required this.paymentCount,
    required this.totalAmount,
    required this.averageAmount,
    required this.percentageOfTotal,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServiceStatsEntity &&
          other.serviceId == serviceId &&
          other.serviceName == serviceName &&
          other.appointmentCount == appointmentCount &&
          other.paymentCount == paymentCount &&
          other.totalAmount == totalAmount &&
          other.averageAmount == averageAmount &&
          other.percentageOfTotal == percentageOfTotal;

  @override
  int get hashCode => Object.hash(serviceId, serviceName, appointmentCount,
      paymentCount, totalAmount, averageAmount, percentageOfTotal);
}
