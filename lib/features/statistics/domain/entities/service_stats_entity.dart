/// Uso de cada servicio en citas pagadas (`GET /payments/stats/by-service`).
///
/// Ojo: hoy el backend calcula [totalAmount] como **precio de lista actual ×
/// veces usado** (no lo cobrado ni lo reembolsado), así que no cuadra con los
/// ingresos netos y [percentageOfTotal] puede pasar de 100.
class ServiceStatsEntity {
  final String serviceId;
  final String serviceName;

  /// Veces que el servicio aparece en citas con un pago completado.
  final int paymentCount;
  final double totalAmount;

  /// Precio de lista actual del servicio.
  final double averageAmount;
  final double percentageOfTotal;

  const ServiceStatsEntity({
    required this.serviceId,
    required this.serviceName,
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
          other.paymentCount == paymentCount &&
          other.totalAmount == totalAmount &&
          other.averageAmount == averageAmount &&
          other.percentageOfTotal == percentageOfTotal;

  @override
  int get hashCode => Object.hash(serviceId, serviceName, paymentCount,
      totalAmount, averageAmount, percentageOfTotal);
}
