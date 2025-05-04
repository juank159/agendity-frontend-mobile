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

  // factory AppointmentModel.fromJson(Map<String, dynamic> json) {
  //   final client = json['client'];
  //   final services = json['services'] as List<dynamic>;
  //   final professional = json['professional'];

  //   // Parsear la fecha manteniendo la hora local
  //   final dateTime = DateTime.parse(json['date']).toLocal();

  //   print('DEBUG - Fecha del servidor: ${json['date']}');
  //   print('DEBUG - Fecha parseada local: ${dateTime.toString()}');

  //   final totalDuration = services.fold<int>(
  //     0,
  //     (sum, service) =>
  //         sum + (int.parse(service['duration']?.toString() ?? '30')),
  //   );

  //   return AppointmentModel(
  //     id: json['id']?.toString() ?? '',
  //     title: services.map((s) => s['name']?.toString() ?? '').join(', '),
  //     startTime: dateTime,
  //     endTime: dateTime.add(Duration(minutes: totalDuration)),
  //     clientName: '${client['name']} ${client['lastname']}'.trim(),
  //     serviceTypes: services.map((s) => s['name']?.toString() ?? '').toList(),
  //     notes: json['notes']?.toString(),
  //     status: json['status']?.toString() ?? AppointmentEntity.STATUS_PENDING,
  //     colors: services
  //         .map((s) => s['color']?.toString())
  //         .where((color) => color != null && color.isNotEmpty)
  //         .cast<String>()
  //         .toList(),
  //     serviceIds: services.map((s) => s['id']?.toString() ?? '').toList(),
  //     clientId: client['id']?.toString() ?? '',
  //     professionalId: professional['id']?.toString(),
  //     ownerId: json['ownerId']?.toString(),
  //     paymentStatus: json['payment_status']?.toString() ??
  //         AppointmentEntity.PAYMENT_PENDING,
  //     totalPrice: json['total_price']?.toString() ?? '0',
  //   );
  // }

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    final client = json['client'];
    final services = json['services'] as List<dynamic>;
    final professional = json['professional'];

    // Priorizar professionalId sobre professional.id
    final professionalId = json['professionalId'] ?? professional['id'];

    // Priorizar clientId sobre client.id
    final clientId = json['clientId'] ?? client['id'];

    // Parsear la fecha manteniendo la hora local
    final dateTime = DateTime.parse(json['date']).toLocal();

    print('DEBUG - Fecha del servidor: ${json['date']}');
    print('DEBUG - Fecha parseada local: ${dateTime.toString()}');

    final totalDuration = services.fold<int>(
      0,
      (sum, service) =>
          sum + (int.parse(service['duration']?.toString() ?? '30')),
    );

    return AppointmentModel(
      id: json['id']?.toString() ?? '',
      title: services.map((s) => s['name']?.toString() ?? '').join(', '),
      startTime: dateTime,
      endTime: dateTime.add(Duration(minutes: totalDuration)),
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
      clientId: clientId,
      professionalId: professionalId,
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
    final localDateTime = startTime.toLocal();
    print('DEBUG - Hora local al crear: ${localDateTime.toString()}');

    return AppointmentModel(
      id: '',
      title: '',
      startTime: localDateTime,
      endTime: localDateTime,
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

  factory AppointmentModel.forUpdate({
    required String id,
    required String professionalId,
    required List<String> serviceIds,
    required DateTime startTime,
    required DateTime endTime,
    String? notes,
  }) {
    return AppointmentModel(
      id: id,
      title: '',
      startTime: startTime,
      endTime: endTime,
      clientName: '',
      serviceTypes: [],
      status: AppointmentEntity.STATUS_PENDING,
      serviceIds: serviceIds,
      clientId: '',
      professionalId: professionalId,
      totalPrice: '0',
      notes: notes,
    );
  }

  Map<String, dynamic> toJson() {
    // La fecha ya está en local, solo necesitamos agregarle el offset
    final dateString = startTime.toLocal().toIso8601String();

    print('DEBUG - Fecha original (local): ${startTime.toString()}');
    print('DEBUG - Fecha a enviar: $dateString');

    // Asegurarnos de incluir todos los campos requeridos por el API
    return {
      'client_id': clientId,
      'professional_id': professionalId,
      'service_ids': serviceIds,
      'date': dateString,
      'notes': notes ?? '',
      // No incluir owner_id si es nulo, ya que el backend podría requerir que sea un UUID válido
      if (ownerId != null && ownerId!.isNotEmpty) 'owner_id': ownerId,
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
