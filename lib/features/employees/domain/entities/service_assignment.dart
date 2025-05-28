// lib/features/employees/domain/entities/service_assignment.dart
// ARCHIVO COMPLETO - Asegúrate de que se vea exactamente así

class ServiceAssignment {
  final String serviceId;
  final double commissionPercentage;
  final double? customPrice;

  ServiceAssignment({
    required this.serviceId,
    required this.commissionPercentage,
    this.customPrice,
  });

  Map<String, dynamic> toJson() {
    return {
      'serviceId': serviceId,
      'commissionPercentage': commissionPercentage,
      if (customPrice != null) 'customPrice': customPrice,
    };
  }

  @override
  String toString() {
    return 'ServiceAssignment{serviceId: $serviceId, commissionPercentage: $commissionPercentage, customPrice: $customPrice}';
  }
}
