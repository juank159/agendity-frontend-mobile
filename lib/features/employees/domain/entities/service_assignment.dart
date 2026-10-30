/// Servicio que atiende un profesional (`user_services`), con su excepción
/// de comisión (0–100 %) y, si lo tiene, un precio propio distinto del de
/// lista.
///
/// D-16 (8.02): [commissionPercentage] `null` = sin excepción, se usa la
/// comisión general del profesional; `0` es un 0 % de verdad.
class ServiceAssignment {
  final String serviceId;

  /// Nombre del servicio; solo llega en las lecturas.
  final String? serviceName;

  final double? commissionPercentage;
  final double? customPrice;

  /// Asignación activa (`user_services.isActive`): una inactiva no cuenta
  /// como servicio que el profesional hace (7.03).
  final bool isActive;

  const ServiceAssignment({
    required this.serviceId,
    this.serviceName,
    this.commissionPercentage,
    this.customPrice,
    this.isActive = true,
  });

  bool get hasCommissionException => commissionPercentage != null;

  /// Comisión que aplica en este servicio con la general [generalPercentage].
  double effectiveCommission(double generalPercentage) =>
      commissionPercentage ?? generalPercentage;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServiceAssignment &&
          other.serviceId == serviceId &&
          other.serviceName == serviceName &&
          other.commissionPercentage == commissionPercentage &&
          other.customPrice == customPrice &&
          other.isActive == isActive;

  @override
  int get hashCode =>
      Object.hash(serviceId, serviceName, commissionPercentage, customPrice,
          isActive);

  @override
  String toString() =>
      'ServiceAssignment($serviceId, comisión: $commissionPercentage, '
      'precio: $customPrice)';
}
