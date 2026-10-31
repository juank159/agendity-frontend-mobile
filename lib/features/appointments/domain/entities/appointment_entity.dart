import 'package:login_signup/common/enums/appointment_payment_status_enum.dart';
import 'package:login_signup/common/enums/appointment_status_enum.dart';
import 'package:login_signup/core/utils/business_time_zone.dart';
import 'package:login_signup/core/utils/deep_equality.dart';
import 'package:login_signup/features/appointments/domain/entities/appointment_client.dart';
import 'package:login_signup/features/appointments/domain/entities/appointment_source.dart';
import 'package:login_signup/features/appointments/domain/entities/appointment_service_line.dart';

export 'package:login_signup/common/enums/appointment_payment_status_enum.dart';
export 'package:login_signup/common/enums/appointment_status_enum.dart';
export 'package:login_signup/features/appointments/domain/entities/appointment_client.dart';
export 'package:login_signup/features/appointments/domain/entities/appointment_source.dart';
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

  /// Inicio y fin como se guardaron: hora de pared en la zona propia de la
  /// cita ([timeZone]; sin zona, la del negocio). La UI usa [startTime] y
  /// [endTime], que están en la zona ACTUAL del negocio.
  final DateTime _recordStart;
  final DateTime _recordEnd;

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

  /// `WEB` = reserva del link público (D-17). Sin el campo, `APP`.
  final AppointmentSource source;

  /// Conflicto al sincronizar lo hecho sin conexión (10.01b, D-18): la cita
  /// se guardó pero hay que **moverla** (`SLOT_UNAVAILABLE`,
  /// `OUTSIDE_BUSINESS_HOURS`, profesional inactivo…). Mientras tanto no
  /// ocupa hueco. Moverla lo limpia.
  final bool needsReschedule;

  /// Código del conflicto ([needsReschedule]); `null` sin conflicto.
  final String? syncConflict;

  const AppointmentEntity({
    required this.id,
    required this.client,
    required this.professionalId,
    this.professionalName,
    required this.services,
    required DateTime startTime,
    required DateTime endTime,
    this.status = AppointmentStatus.PENDING,
    this.paymentStatus = AppointmentPaymentStatus.PENDING,
    required this.totalPrice,
    this.notes,
    this.cancellationReason,
    this.reminderSent = false,
    this.reminderSentAt,
    this.createdAt,
    this.timeZone,
    this.source = AppointmentSource.APP,
    this.needsReschedule = false,
    this.syncConflict,
  })  : _recordStart = startTime,
        _recordEnd = endTime;

  /// Instante (UTC) del inicio, para comparar citas de zonas distintas.
  DateTime get startInstant =>
      BusinessTimeZone.toInstant(_recordStart, timeZone);

  /// La cita se guardó en otra zona que la ACTUAL del negocio (el negocio
  /// cambió de zona después, 6.03). Una zona desconocida cuenta como la del
  /// negocio, igual que en [startInstant].
  bool get isInOtherTimeZone {
    final own = BusinessTimeZone.canonicalName(timeZone);
    return own != null && own != BusinessTimeZone.current;
  }

  /// Inicio en la zona ACTUAL del negocio (decisión de 6.05: la agenda es el
  /// calendario del negocio, así que toda cita se pinta según su instante en
  /// la zona de hoy del negocio, igual que las horas libres).
  DateTime get startTime => isInOtherTimeZone
      ? BusinessTimeZone.toWallClock(startInstant)
      : _recordStart;

  /// Fin en la zona ACTUAL del negocio: inicio + la suma de las duraciones
  /// de [services] (como el backend).
  DateTime get endTime => startTime.add(duration);

  /// Inicio con la hora de pared de su propia zona ([timeZone]): "Agendada
  /// en hora de Bogotá: 10:00".
  DateTime get recordStartTime => _recordStart;

  String get clientName => client.fullName;
  List<String> get serviceIds => [for (final s in services) s.serviceId];
  List<String> get serviceNames => [for (final s in services) s.name];
  Duration get duration => _recordEnd.difference(_recordStart);

  bool get isPending => status == AppointmentStatus.PENDING;
  bool get isConfirmed => status == AppointmentStatus.CONFIRMED;
  bool get isCompleted => status == AppointmentStatus.COMPLETED;
  bool get isCancelled => status == AppointmentStatus.CANCELLED;

  /// `COMPLETED` o `CANCELLED`: no admite más cambios de estado.
  bool get isFinal => status.isFinal;

  /// Ocupa su hueco en la agenda (una cancelada lo libera, y una que quedó
  /// para mover tras sincronizar, D-18).
  bool get blocksSlot => !isCancelled && !needsReschedule;

  /// Se puede completar (también sin pagar, 2.15). Además debe haber
  /// empezado: ver [canCompleteAt].
  bool get canComplete => isPending || isConfirmed;

  bool get isWebBooking => source == AppointmentSource.WEB;

  /// Ya empezó en [now] (hora de pared del negocio, `BusinessTimeZone.now()`).
  bool hasStartedAt(DateTime now) =>
      !startInstant.isAfter(BusinessTimeZone.toInstant(now));

  /// Se puede completar en [now]: pendiente o confirmada y ya empezada
  /// (7.03: si no, el backend responde `APPOINTMENT_NOT_STARTED`).
  bool canCompleteAt(DateTime now) => canComplete && hasStartedAt(now);

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

  /// [startTime]/[endTime] son horas de pared en la zona de la cita
  /// ([timeZone]), como en el constructor.
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
    AppointmentSource? source,
    bool? needsReschedule,
    String? syncConflict,
  }) =>
      AppointmentEntity(
        id: id ?? this.id,
        client: client ?? this.client,
        professionalId: professionalId ?? this.professionalId,
        professionalName: professionalName ?? this.professionalName,
        services: services ?? this.services,
        startTime: startTime ?? _recordStart,
        endTime: endTime ?? _recordEnd,
        status: status ?? this.status,
        paymentStatus: paymentStatus ?? this.paymentStatus,
        totalPrice: totalPrice ?? this.totalPrice,
        notes: notes ?? this.notes,
        cancellationReason: cancellationReason ?? this.cancellationReason,
        reminderSent: reminderSent ?? this.reminderSent,
        reminderSentAt: reminderSentAt ?? this.reminderSentAt,
        createdAt: createdAt ?? this.createdAt,
        timeZone: timeZone ?? this.timeZone,
        source: source ?? this.source,
        needsReschedule: needsReschedule ?? this.needsReschedule,
        syncConflict: syncConflict ?? this.syncConflict,
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
          other._recordStart == _recordStart &&
          other._recordEnd == _recordEnd &&
          other.status == status &&
          other.paymentStatus == paymentStatus &&
          other.totalPrice == totalPrice &&
          other.notes == notes &&
          other.cancellationReason == cancellationReason &&
          other.reminderSent == reminderSent &&
          other.reminderSentAt == reminderSentAt &&
          other.createdAt == createdAt &&
          other.timeZone == timeZone &&
          other.source == source &&
          other.needsReschedule == needsReschedule &&
          other.syncConflict == syncConflict;

  @override
  int get hashCode => Object.hash(
        id,
        client,
        professionalId,
        professionalName,
        Object.hashAll(services),
        _recordStart,
        _recordEnd,
        status,
        paymentStatus,
        totalPrice,
        notes,
        cancellationReason,
        reminderSent,
        reminderSentAt,
        createdAt,
        timeZone,
        source,
        needsReschedule,
        syncConflict,
      );

  @override
  String toString() =>
      'AppointmentEntity($id, $clientName, $startTime, ${status.name}, '
      '${paymentStatus.name}, $totalPrice)';
}
