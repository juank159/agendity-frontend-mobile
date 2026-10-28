import 'package:login_signup/core/utils/date_codec.dart';
import 'package:login_signup/core/utils/json_read.dart';
import 'package:login_signup/features/appointments/domain/entities/appointment_changes.dart';
import 'package:login_signup/features/appointments/domain/entities/appointment_entity.dart';
import 'package:login_signup/features/appointments/domain/entities/manual_reminder.dart';
import 'package:login_signup/features/appointments/domain/entities/new_appointment.dart';

/// DTO de una cita de `/appointments` (backend: `Appointment` con `client`,
/// `professional` y `services`). Mezcla camelCase (`professionalId`,
/// `reminderSent`) y snake_case (`payment_status`, `total_price`), como el
/// backend. `total_price` y los precios llegan como texto (`numeric`).
class AppointmentModel {
  final String id;
  final AppointmentClient client;
  final String professionalId;
  final String? professionalName;
  final List<AppointmentServiceLine> services;
  final DateTime start;
  final AppointmentStatus status;
  final AppointmentPaymentStatus paymentStatus;
  final double totalPrice;
  final String? notes;
  final String? cancellationReason;
  final bool reminderSent;
  final DateTime? reminderSentAt;
  final DateTime? createdAt;

  const AppointmentModel({
    required this.id,
    required this.client,
    required this.professionalId,
    this.professionalName,
    required this.services,
    required this.start,
    required this.status,
    required this.paymentStatus,
    required this.totalPrice,
    this.notes,
    this.cancellationReason,
    this.reminderSent = false,
    this.reminderSentAt,
    this.createdAt,
  });

  /// Sin `id` o sin `date` no es una cita: lanza `FormatException` (el
  /// repositorio lo convierte en `ServerFailure`).
  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    final id = JsonRead.asOptionalString(json['id']);
    final start = DateCodec.tryDecode(json['date']);
    if (id == null || start == null) {
      throw const FormatException('Cita sin id o sin fecha');
    }
    final client = JsonRead.asMap(json['client']);
    final professional = JsonRead.asMap(json['professional']);
    final professionalName = professional == null
        ? ''
        : '${JsonRead.asString(professional['name'])} '
                '${JsonRead.asString(professional['lastname'])}'
            .trim();

    return AppointmentModel(
      id: id,
      client: AppointmentClient(
        id: JsonRead.asString(json['clientId'] ?? client?['id']),
        name: JsonRead.asString(client?['name']),
        lastname: JsonRead.asString(client?['lastname']),
        phone: JsonRead.asOptionalString(client?['phone']),
      ),
      professionalId:
          JsonRead.asString(json['professionalId'] ?? professional?['id']),
      professionalName: professionalName.isEmpty ? null : professionalName,
      services: JsonRead.asMapList(json['services'])
          .map(_serviceLineFromJson)
          .toList(growable: false),
      start: start,
      status: AppointmentStatus.fromApi(json['status']) ??
          AppointmentStatus.PENDING,
      paymentStatus: AppointmentPaymentStatus.fromApi(json['payment_status']) ??
          AppointmentPaymentStatus.PENDING,
      totalPrice: JsonRead.asDouble(json['total_price']),
      notes: JsonRead.asOptionalString(json['notes']),
      cancellationReason:
          JsonRead.asOptionalString(json['cancellation_reason']),
      reminderSent: JsonRead.asBool(
          json['reminderSent'] ?? json['reminder_sent'],
          fallback: false),
      reminderSentAt: DateCodec.tryDecode(
          json['reminderSentAt'] ?? json['reminder_sent_at']),
      createdAt: DateCodec.tryDecode(json['created_at']),
    );
  }

  /// `appointment_price` = precio en la cita (2.29); si faltara (respuesta
  /// anterior a 2.29), el `price` del servicio. Duración como el backend:
  /// sin duración o ≤ 0 cuenta 30 min.
  static AppointmentServiceLine _serviceLineFromJson(
      Map<String, dynamic> json) {
    final duration = JsonRead.asInt(json['duration']);
    final hasCurrentPrice = json['price'] != null;
    return AppointmentServiceLine(
      serviceId: JsonRead.asString(json['id']),
      name: JsonRead.asString(json['name']),
      durationMinutes: duration > 0
          ? duration
          : AppointmentServiceLine.defaultDurationMinutes,
      color: JsonRead.asOptionalString(json['color']),
      price: JsonRead.asDouble(json['appointment_price'] ?? json['price']),
      currentPrice: hasCurrentPrice ? JsonRead.asDouble(json['price']) : null,
    );
  }

  AppointmentEntity toEntity() => AppointmentEntity(
        id: id,
        client: client,
        professionalId: professionalId,
        professionalName: professionalName,
        services: services,
        startTime: start,
        endTime: start.add(Duration(
            minutes: services.fold(0, (sum, s) => sum + s.durationMinutes))),
        status: status,
        paymentStatus: paymentStatus,
        totalPrice: totalPrice,
        notes: notes,
        cancellationReason: cancellationReason,
        reminderSent: reminderSent,
        reminderSentAt: reminderSentAt,
        createdAt: createdAt,
      );
}

/// Cuerpo de `POST /appointments` (`CreateAppointmentDto`). Sin `owner_id`
/// (el negocio sale del JWT) ni precio (lo calcula el backend).
abstract final class NewAppointmentModel {
  static Map<String, dynamic> toJson(NewAppointment appointment) => {
        'client_id': appointment.clientId,
        'professional_id': appointment.professionalId,
        'service_ids': appointment.serviceIds,
        'date': DateCodec.encode(appointment.start),
        if (appointment.notes != null) 'notes': appointment.notes,
      };
}

/// Cuerpo de `PATCH /appointments/:id`: solo los campos que cambian.
abstract final class AppointmentChangesModel {
  static Map<String, dynamic> toJson(AppointmentChanges changes) => {
        if (changes.clientId != null) 'client_id': changes.clientId,
        if (changes.professionalId != null)
          'professional_id': changes.professionalId,
        if (changes.serviceIds != null) 'service_ids': changes.serviceIds,
        if (changes.start != null) 'date': DateCodec.encode(changes.start!),
        if (changes.notes != null) 'notes': changes.notes,
      };
}

/// Respuesta de `POST /appointments/:id/send-reminder`.
abstract final class ManualReminderModel {
  static ManualReminder fromJson(Map<String, dynamic> json) => ManualReminder(
        appointmentId: JsonRead.asString(json['appointmentId']),
        clientId: JsonRead.asString(json['clientId']),
        phone: JsonRead.asString(json['phone']),
        message: JsonRead.asString(json['message']),
        whatsappUrl: JsonRead.asString(json['whatsappUrl']),
      );
}
