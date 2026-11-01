import 'package:login_signup/features/reminders/domain/entities/reminder_rule.dart';

/// Estado de un envío (backend `DELIVERY_STATUSES`): `queued → sent →
/// delivered → read`; `failed` y `skipped` son finales.
enum DeliveryStatus {
  queued,
  sent,
  delivered,
  read,
  failed,
  skipped;

  String get apiValue => name;

  bool get isFinal => this == failed || this == skipped || this == read;

  static DeliveryStatus? fromApi(Object? value) {
    for (final s in values) {
      if (s.name == value) return s;
    }
    return null;
  }
}

/// Motivos de un `skipped`/`failed` (backend `DELIVERY_REASONS`).
abstract final class DeliveryReason {
  static const quota = 'QUOTA';
  static const noConsent = 'NO_CONSENT';
  static const optedOut = 'OPTED_OUT';
  static const invalidPhone = 'INVALID_PHONE';
  static const tooLate = 'TOO_LATE';
  static const bookedAfter = 'BOOKED_AFTER';
  static const appointmentChanged = 'APPOINTMENT_CHANGED';
  static const ruleDisabled = 'RULE_DISABLED';
  static const remindersDisabled = 'REMINDERS_DISABLED';
  static const alreadyBooked = 'ALREADY_BOOKED';
  static const stale = 'STALE';
  static const maxAttempts = 'MAX_ATTEMPTS';
  static const provider = 'PROVIDER_ERROR';
}

/// Un mensaje del historial de recordatorios. Horas en el reloj del negocio.
class ReminderDelivery {
  final String id;
  final ReminderKind? kind;
  final DeliveryStatus status;

  /// Código de [DeliveryReason] (o `null`).
  final String? reason;
  final String? clientId;
  final String? appointmentId;
  final ReminderCategory? category;

  /// E.164 al que se envió (o se iba a enviar).
  final String? phone;

  /// Texto (canal simulado y envío manual).
  final String? body;
  final int attempts;
  final DateTime? scheduledFor;
  final DateTime? sentAt;
  final DateTime? deliveredAt;
  final DateTime? readAt;
  final DateTime? failedAt;
  final DateTime? createdAt;

  const ReminderDelivery({
    required this.id,
    this.kind,
    required this.status,
    this.reason,
    this.clientId,
    this.appointmentId,
    this.category,
    this.phone,
    this.body,
    this.attempts = 0,
    this.scheduledFor,
    this.sentAt,
    this.deliveredAt,
    this.readAt,
    this.failedAt,
    this.createdAt,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReminderDelivery &&
          other.id == id &&
          other.status == status &&
          other.reason == reason &&
          other.attempts == attempts &&
          other.sentAt == sentAt;

  @override
  int get hashCode => Object.hash(id, status, reason, attempts, sentAt);
}

/// Filtros del historial (`GET /reminders/deliveries`).
class DeliveriesQuery {
  /// Tope del backend.
  static const maxLimit = 200;

  final DeliveryStatus? status;
  final String? clientId;
  final int limit;
  final int offset;

  const DeliveriesQuery(
      {this.status, this.clientId, this.limit = 50, this.offset = 0});
}
