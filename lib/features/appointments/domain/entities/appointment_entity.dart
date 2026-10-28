import 'package:login_signup/common/enums/appointment_payment_status_enum.dart';
import 'package:login_signup/common/enums/appointment_status_enum.dart';
import 'package:login_signup/core/utils/business_time_zone.dart';
import 'package:login_signup/core/utils/deep_equality.dart';
import 'package:login_signup/features/appointments/domain/entities/appointment_client.dart';
import 'package:login_signup/features/appointments/domain/entities/appointment_service_line.dart';

export 'package:login_signup/common/enums/appointment_payment_status_enum.dart';
export 'package:login_signup/common/enums/appointment_status_enum.dart';
export 'package:login_signup/features/appointments/domain/entities/appointment_client.dart';
export 'package:login_signup/features/appointments/domain/entities/appointment_service_line.dart';

/// Cita (backend: `appointments`). Pura: sin colores ni textos de UI (los
/// pone presentation, `appointment_status_ui.dart`).
///
/// Reglas del backend que refleja (ARQUITECTURA §2.1, máquina de estados):
/// `PENDING → CONFIRMED → COMPLETED`, `PENDING → COMPLETED` (completar sin
/// pagar), `PENDING|CONFIRMED → CANCELLED` salvo con pagos; `COMPLETED` y
/// `CANCELLED` son finales. El primer pago confirma la cita.
class AppointmentEntity {
  final String id;
  final AppointmentClient client;
  final String professionalId;

  /// Nombre del profesional si vino en la respuesta (`professional`).
  final String? professionalName;

  /// Servicios en el orden de la cita, con el precio guardado en ella.
  final List<AppointmentServiceLine> services;

  /// Hora de pared de la cita en su zona ([timeZone]; D-15).
  final DateTime startTime;

  /// Inicio + la suma de las duraciones de [services] (como el backend).
  final DateTime endTime;

  final AppointmentStatus status;
  final AppointmentPaymentStatus paymentStatus;

  /// Total en COP = suma de los precios guardados de [services] (`total_price`).
  final double totalPrice;

  final String? notes;
  final String? cancellationReason;

  /// Recordatorio MANUAL al cliente (`wa.me`) ya enviado. Mover la cita a otra
  /// fecha lo reinicia (2.18).
  final bool reminderSent;
  final DateTime? reminderSentAt;
  final DateTime? createdAt;

  /// Zona IANA con la que se creó o se movió por última vez la cita (6.03);
  /// sus horas están en ella. `null` = la del negocio. Solo difiere de la del
  /// negocio si este cambió de zona después.
  final String? timeZone;

  const AppointmentEntity({
    required this.id,
    required this.client,
    required this.professionalId,
    this.professionalName,
    required this.services,
    required this.startTime,
    required this.endTime,
    this.status = AppointmentStatus.PENDING,
    this.paymentStatus = AppointmentPaymentStatus.PENDING,
    required this.totalPrice,
    this.notes,
    this.cancellationReason,
    this.reminderSent = false,
    this.reminderSentAt,
    this.createdAt,
    this.timeZone,
  });

  /// Instante (UTC) del inicio, para comparar citas de zonas distintas.
  DateTime get startInstant => BusinessTimeZone.toInstant(startTime, timeZone);

  String get clientName => client.fullName;
  List<String> get serviceIds => [for (final s in services) s.serviceId];
  List<String> get serviceNames => [for (final s in services) s.name];
  Duration get duration => endTime.difference(startTime);

  bool get isPending => status == AppointmentStatus.PENDING;
  bool get isConfirmed => status == AppointmentStatus.CONFIRMED;
  bool get isCompleted => status == AppointmentStatus.COMPLETED;
  bool get isCancelled => status == AppointmentStatus.CANCELLED;

  /// `COMPLETED` o `CANCELLED`: no admite más cambios de estado.
  bool get isFinal => status.isFinal;

  /// Ocupa su hueco en la agenda (solo una cancelada lo libera).
  bool get blocksSlot => !isCancelled;

  /// Se puede completar (también sin pagar, 2.15).
  bool get canComplete => isPending || isConfirmed;

  /// Se puede cancelar: no es final y no le queda nada pagado (si no, el
  /// backend responde `APPOINTMENT_PAID`).
  bool get canCancel =>
      (isPending || isConfirmed) && !paymentStatus.hasNetPayments;

  /// Admite un pago: no está cancelada ni pagada del todo.
  bool get canBePaid => !isCancelled && !paymentStatus.isFullyPaid;

  bool get isFullyPaid => paymentStatus.isFullyPaid;

  /// Saldo pendiente que se sabe sin consultar los pagos: el total si no hay
  /// nada pagado (o se devolvió todo), 0 si está pagada. `null` con un
  /// anticipo (`PARTIAL`): hay que pedirlo a payments
  /// (`GetAppointmentBalanceUseCase`).
  double? get knownBalanceDue => switch (paymentStatus) {
        AppointmentPaymentStatus.COMPLETED => 0,
        AppointmentPaymentStatus.PARTIAL => null,
        _ => totalPrice,
      };

  /// Le falta el recordatorio manual: pendiente o confirmada, futura y sin
  /// recordatorio enviado (el backend solo lo prepara en esos estados).
  /// [now] es la hora de pared del negocio (`BusinessTimeZone.now()`).
  bool needsReminderAt(DateTime now) =>
      (isPending || isConfirmed) &&
      !reminderSent &&
      startInstant.isAfter(BusinessTimeZone.toInstant(now));

  AppointmentEntity copyWith({
    String? id,
    AppointmentClient? client,
    String? professionalId,
    String? professionalName,
    List<AppointmentServiceLine>? services,
    DateTime? startTime,
    DateTime? endTime,
    AppointmentStatus? status,
    AppointmentPaymentStatus? paymentStatus,
    double? totalPrice,
    String? notes,
    String? cancellationReason,
    bool? reminderSent,
    DateTime? reminderSentAt,
    DateTime? createdAt,
    String? timeZone,
  }) =>
      AppointmentEntity(
        id: id ?? this.id,
        client: client ?? this.client,
        professionalId: professionalId ?? this.professionalId,
        professionalName: professionalName ?? this.professionalName,
        services: services ?? this.services,
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
        status: status ?? this.status,
        paymentStatus: paymentStatus ?? this.paymentStatus,
        totalPrice: totalPrice ?? this.totalPrice,
        notes: notes ?? this.notes,
        cancellationReason: cancellationReason ?? this.cancellationReason,
        reminderSent: reminderSent ?? this.reminderSent,
        reminderSentAt: reminderSentAt ?? this.reminderSentAt,
        createdAt: createdAt ?? this.createdAt,
        timeZone: timeZone ?? this.timeZone,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppointmentEntity &&
          other.id == id &&
          other.client == client &&
          other.professionalId == professionalId &&
          other.professionalName == professionalName &&
          DeepEquality.lists(other.services, services) &&
          other.startTime == startTime &&
          other.endTime == endTime &&
          other.status == status &&
          other.paymentStatus == paymentStatus &&
          other.totalPrice == totalPrice &&
          other.notes == notes &&
          other.cancellationReason == cancellationReason &&
          other.reminderSent == reminderSent &&
          other.reminderSentAt == reminderSentAt &&
          other.createdAt == createdAt &&
          other.timeZone == timeZone;

  @override
  int get hashCode => Object.hash(
        id,
        client,
        professionalId,
        professionalName,
        Object.hashAll(services),
        startTime,
        endTime,
        status,
        paymentStatus,
        totalPrice,
        notes,
        cancellationReason,
        reminderSent,
        reminderSentAt,
        createdAt,
        timeZone,
      );

  @override
  String toString() =>
      'AppointmentEntity($id, $clientName, $startTime, ${status.name}, '
      '${paymentStatus.name}, $totalPrice)';
}
