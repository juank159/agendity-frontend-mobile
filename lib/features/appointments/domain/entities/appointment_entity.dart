class AppointmentEntity {
  final String id;
  final String title;
  final DateTime startTime;
  final DateTime endTime;
  final String clientName;
  final String serviceType;
  final String? notes;
  final String? status;
  final String? color;

  // Campos nuevos
  final String? ownerId;
  final String? professionalId;
  final String? paymentStatus;
  final String? totalPrice;

  const AppointmentEntity({
    required this.id,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.clientName,
    required this.serviceType,
    this.notes,
    this.status,
    this.color,
    this.ownerId,
    this.professionalId,
    this.paymentStatus,
    this.totalPrice,
  });

  @override
  String toString() {
    return 'AppointmentEntity(id: $id, title: $title, startTime: $startTime, endTime: $endTime, clientName: $clientName, serviceType: $serviceType, notes: $notes, status: $status, color: $color, ownerId: $ownerId, professionalId: $professionalId, paymentStatus: $paymentStatus, totalPrice: $totalPrice)';
  }
}
