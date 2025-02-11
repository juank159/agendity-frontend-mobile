// // appointment_model.dart
// import 'package:login_signup/features/appointments/domain/entities/appointment_entity.dart';

// class AppointmentModel extends AppointmentEntity {
//   final String serviceId;
//   final String clientId;
//   final String professionalId;
//   final String ownerId;
//   final String paymentStatus;
//   final String totalPrice;

//   AppointmentModel({
//     required super.id,
//     required super.title,
//     required super.startTime,
//     required super.endTime,
//     required super.clientName,
//     required super.serviceType,
//     required this.serviceId,
//     required this.clientId,
//     required this.professionalId,
//     required this.ownerId,
//     required this.paymentStatus,
//     required this.totalPrice,
//     super.notes,
//     super.status,
//     super.color,
//   });

//   factory AppointmentModel.fromJson(Map<String, dynamic> json) {
//     final client = json['client'];
//     final service = json['service'];
//     final professional = json['professional'];

//     return AppointmentModel(
//       id: json['id'],
//       title: service['name'] ?? '',
//       startTime: DateTime.parse(json['date']),
//       endTime: DateTime.parse(json['date'])
//           .add(Duration(minutes: service['duration'] ?? 30)),
//       clientName: '${client['name']} ${client['lastname']}',
//       serviceType: service['name'] ?? '',
//       notes: json['notes'],
//       status: json['status'],
//       color: service['color'],
//       serviceId: service['id'],
//       clientId: client['id'],
//       professionalId: professional['id'],
//       ownerId: json['ownerId'],
//       paymentStatus: json['payment_status'],
//       totalPrice: json['total_price'],
//     );
//   }

//   factory AppointmentModel.create({
//     required String serviceId,
//     required String clientId,
//     required String professionalId,
//     required String ownerId,
//     required DateTime startTime,
//     required String totalPrice,
//     String? notes,
//   }) {
//     return AppointmentModel(
//       id: '',
//       title: '',
//       startTime: startTime,
//       endTime: startTime,
//       clientName: '',
//       serviceType: '',
//       serviceId: serviceId,
//       clientId: clientId,
//       professionalId: professionalId,
//       ownerId: ownerId,
//       paymentStatus: 'PENDING',
//       totalPrice: totalPrice,
//       notes: notes,
//       status: 'PENDING',
//     );
//   }

//   static AppointmentModel fromEntity(AppointmentEntity entity) {
//     if (entity is AppointmentModel) {
//       return entity;
//     }

//     throw UnimplementedError(
//       'No se puede convertir una entidad base a modelo sin los campos adicionales requeridos',
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       'client_id': clientId,
//       'professional_id': professionalId,
//       'service_id': serviceId,
//       'owner_id': ownerId,
//       'date': startTime.toIso8601String(),
//       'total_price': double.tryParse(totalPrice) ?? 0.0,
//       'notes': notes ?? '',
//     };
//   }

//   AppointmentModel copyWith({
//     String? id,
//     String? title,
//     DateTime? startTime,
//     DateTime? endTime,
//     String? clientName,
//     String? serviceType,
//     String? notes,
//     String? status,
//     String? color,
//     String? serviceId,
//     String? clientId,
//     String? professionalId,
//     String? ownerId,
//     String? paymentStatus,
//     String? totalPrice,
//   }) {
//     return AppointmentModel(
//       id: id ?? this.id,
//       title: title ?? this.title,
//       startTime: startTime ?? this.startTime,
//       endTime: endTime ?? this.endTime,
//       clientName: clientName ?? this.clientName,
//       serviceType: serviceType ?? this.serviceType,
//       notes: notes ?? this.notes,
//       status: status ?? this.status,
//       color: color ?? this.color,
//       serviceId: serviceId ?? this.serviceId,
//       clientId: clientId ?? this.clientId,
//       professionalId: professionalId ?? this.professionalId,
//       ownerId: ownerId ?? this.ownerId,
//       paymentStatus: paymentStatus ?? this.paymentStatus,
//       totalPrice: totalPrice ?? this.totalPrice,
//     );
//   }
// }

// appointment_model.dart
import 'package:login_signup/features/appointments/domain/entities/appointment_entity.dart';

class AppointmentModel extends AppointmentEntity {
  final String serviceId;
  final String clientId;
  final String professionalId;
  final String ownerId;
  final String paymentStatus;
  final String totalPrice;

  AppointmentModel({
    required super.id,
    required super.title,
    required super.startTime,
    required super.endTime,
    required super.clientName,
    required super.serviceType,
    required this.serviceId,
    required this.clientId,
    required this.professionalId,
    required this.ownerId,
    required this.paymentStatus,
    required this.totalPrice,
    super.notes,
    super.status,
    super.color,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    final client = json['client'];
    final service = json['service'];
    final professional = json['professional'];
    final dateTime = DateTime.parse(json['date']).toLocal();

    return AppointmentModel(
      id: json['id']?.toString() ?? '',
      title: service['name']?.toString() ?? '',
      startTime: dateTime,
      endTime: dateTime.add(Duration(
          minutes: int.parse(service['duration']?.toString() ?? '30'))),
      clientName: '${client['name']} ${client['lastname']}',
      serviceType: service['name']?.toString() ?? '',
      notes: json['notes']?.toString(),
      status: json['status']?.toString(),
      color: service['color']?.toString(),
      serviceId: service['id']?.toString() ?? '',
      clientId: client['id']?.toString() ?? '',
      professionalId: professional['id']?.toString() ?? '',
      ownerId: json['ownerId']?.toString() ?? '',
      paymentStatus: json['payment_status']?.toString() ?? 'PENDING',
      totalPrice: json['total_price']?.toString() ?? '0',
    );
  }

  factory AppointmentModel.create({
    required String serviceId,
    required String clientId,
    required String professionalId,
    required String ownerId,
    required DateTime startTime,
    required String totalPrice,
    String? notes,
  }) {
    return AppointmentModel(
      id: '',
      title: '',
      startTime: startTime,
      endTime: startTime,
      clientName: '',
      serviceType: '',
      serviceId: serviceId,
      clientId: clientId,
      professionalId: professionalId,
      ownerId: ownerId,
      paymentStatus: 'PENDING',
      totalPrice: totalPrice,
      notes: notes ?? '',
      status: 'PENDING',
    );
  }

  static AppointmentModel fromEntity(AppointmentEntity entity) {
    if (entity is AppointmentModel) {
      return entity;
    }

    throw UnimplementedError(
      'No se puede convertir una entidad base a modelo sin los campos adicionales requeridos',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'client_id': clientId,
      'professional_id': professionalId,
      'service_id': serviceId,
      'owner_id': ownerId,
      'date': startTime.toUtc().toIso8601String(), // Asegurar UTC
      'total_price': double.parse(totalPrice.replaceAll(RegExp(r'[^\d.]'), '')),
      'notes': notes ?? '',
    };
  }

  AppointmentModel copyWith({
    String? id,
    String? title,
    DateTime? startTime,
    DateTime? endTime,
    String? clientName,
    String? serviceType,
    String? notes,
    String? status,
    String? color,
    String? serviceId,
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
      serviceType: serviceType ?? this.serviceType,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      color: color ?? this.color,
      serviceId: serviceId ?? this.serviceId,
      clientId: clientId ?? this.clientId,
      professionalId: professionalId ?? this.professionalId,
      ownerId: ownerId ?? this.ownerId,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      totalPrice: totalPrice ?? this.totalPrice,
    );
  }
}
