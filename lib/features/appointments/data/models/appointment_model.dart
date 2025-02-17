import 'package:login_signup/features/appointments/domain/entities/appointment_entity.dart';
import 'package:intl/intl.dart';

class AppointmentModel extends AppointmentEntity {
  final List<String> serviceIds;
  final String clientId;

  AppointmentModel({
    required super.id,
    required super.title,
    required super.startTime,
    required super.endTime,
    required super.clientName,
    required super.serviceTypes,
    required super.status,
    required super.totalPrice,
    required this.serviceIds,
    required this.clientId,
    super.notes,
    super.colors,
    super.ownerId,
    super.professionalId,
    super.paymentStatus,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    final client = json['client'];
    final services = json['services'] as List<dynamic>;
    final professional = json['professional'];

    // Parseamos la fecha manteniendo la zona horaria original
    final dateTimeUtc = DateTime.parse(json['date']);
    print('DEBUG - Fecha parseada del servidor: $dateTimeUtc');

    final totalDuration = services.fold<int>(
      0,
      (sum, service) =>
          sum + (int.parse(service['duration']?.toString() ?? '30')),
    );

    return AppointmentModel(
      id: json['id']?.toString() ?? '',
      title: services.map((s) => s['name']?.toString() ?? '').join(', '),
      startTime: dateTimeUtc,
      endTime: dateTimeUtc.add(Duration(minutes: totalDuration)),
      clientName: '${client['name']} ${client['lastname']}'.trim(),
      serviceTypes: services.map((s) => s['name']?.toString() ?? '').toList(),
      notes: json['notes']?.toString(),
      status: json['status']?.toString() ?? AppointmentEntity.STATUS_PENDING,
      colors: services
          .map((s) => s['color']?.toString())
          .where((color) => color != null && color.isNotEmpty)
          .cast<String>()
          .toList(),
      serviceIds: services.map((s) => s['id']?.toString() ?? '').toList(),
      clientId: client['id']?.toString() ?? '',
      professionalId: professional['id']?.toString(),
      ownerId: json['ownerId']?.toString(),
      paymentStatus: json['payment_status']?.toString() ??
          AppointmentEntity.PAYMENT_PENDING,
      totalPrice: json['total_price']?.toString() ?? '0',
    );
  }

  factory AppointmentModel.create({
    required List<String> serviceIds,
    required String clientId,
    required String professionalId,
    required String ownerId,
    required DateTime startTime,
    required String totalPrice,
    String? notes,
  }) {
    // Asegurarnos de que la fecha está en UTC
    final utcStartTime = startTime.toUtc();
    print('DEBUG - Fecha original al crear: $startTime');
    print('DEBUG - Fecha UTC al crear: $utcStartTime');

    return AppointmentModel(
      id: '',
      title: '',
      startTime: utcStartTime,
      endTime: utcStartTime,
      clientName: '',
      serviceTypes: [],
      status: AppointmentEntity.STATUS_PENDING,
      serviceIds: serviceIds,
      clientId: clientId,
      professionalId: professionalId,
      ownerId: ownerId,
      paymentStatus: AppointmentEntity.PAYMENT_PENDING,
      totalPrice: totalPrice,
      notes: notes ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    final utcDate = startTime.toUtc();
    final dateString = utcDate.toIso8601String();

    print('DEBUG - Fecha Original: ${startTime.toString()}');
    print('DEBUG - Fecha UTC: ${utcDate.toString()}');
    print('DEBUG - String ISO8601: $dateString');

    return {
      'client_id': clientId,
      'professional_id': professionalId,
      'service_ids': serviceIds,
      'owner_id': ownerId,
      'date': dateString,
      'notes': notes ?? '',
    };
  }

  AppointmentModel copyWith({
    String? id,
    String? title,
    DateTime? startTime,
    DateTime? endTime,
    String? clientName,
    List<String>? serviceTypes,
    String? notes,
    String? status,
    List<String>? colors,
    List<String>? serviceIds,
    String? clientId,
    String? professionalId,
    String? ownerId,
    String? paymentStatus,
    String? totalPrice,
  }) {
    return AppointmentModel(
      id: id ?? this.id,
      title: title ?? this.title,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      clientName: clientName ?? this.clientName,
      serviceTypes: serviceTypes ?? this.serviceTypes,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      colors: colors ?? this.colors,
      serviceIds: serviceIds ?? this.serviceIds,
      clientId: clientId ?? this.clientId,
      professionalId: professionalId ?? this.professionalId,
      ownerId: ownerId ?? this.ownerId,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      totalPrice: totalPrice ?? this.totalPrice,
    );
  }
}
