/// Servicio que atiende un profesional (`user_services`), con su comisión
/// (0–100 %) y, si lo tiene, un precio propio distinto del de lista.
class ServiceAssignment {
  final String serviceId;

  /// Nombre del servicio; solo llega en las lecturas.
  final String? serviceName;

  final double commissionPercentage;
  final double? customPrice;

  const ServiceAssignment({
    required this.serviceId,
    this.serviceName,
    this.commissionPercentage = 0,
    this.customPrice,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServiceAssignment &&
          other.serviceId == serviceId &&
          other.serviceName == serviceName &&
          other.commissionPercentage == commissionPercentage &&
          other.customPrice == customPrice;

  @override
  int get hashCode =>
      Object.hash(serviceId, serviceName, commissionPercentage, customPrice);

  @override
  String toString() =>
      'ServiceAssignment($serviceId, comisión: $commissionPercentage, '
      'precio: $customPrice)';
}
