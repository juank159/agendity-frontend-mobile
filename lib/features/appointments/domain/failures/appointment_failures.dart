import 'package:login_signup/common/entities/work_hours.dart';
import 'package:login_signup/core/errors/failures.dart';

export 'package:login_signup/features/subscriptions/domain/failures/subscription_failures.dart'
    show TrialLimitReachedFailure, SubscriptionInactiveFailure;

/// Por qué el hueco no está libre (`details.reason` de `SLOT_UNAVAILABLE`,
/// 13.04). Mismos valores que el backend (`SlotUnavailableReason`).
enum SlotUnavailableReason {
  /// Fuera del horario del profesional; `hours` = sus franjas de ese día.
  professionalOffSchedule('PROFESSIONAL_OFF_SCHEDULE'),

  /// Dentro de un bloqueo de tiempo del profesional.
  timeBlock('TIME_BLOCK'),

  /// Se cruza con otra cita no cancelada.
  appointmentOverlap('APPOINTMENT_OVERLAP');

  final String apiValue;
  const SlotUnavailableReason(this.apiValue);

  /// `null` si no viene o no se conoce (un backend más nuevo).
  static SlotUnavailableReason? fromApi(Object? value) {
    for (final reason in values) {
      if (reason.apiValue == value) return reason;
    }
    return null;
  }
}

/// Por qué la hora está fuera del horario del negocio (`details.reason` de
/// `OUTSIDE_BUSINESS_HOURS`, 13.04).
enum OutsideBusinessHoursReason {
  /// Ese día el negocio no abre.
  businessClosedDay('BUSINESS_CLOSED_DAY'),

  /// Abre, pero la cita no cabe; `hours` = las franjas de apertura del día.
  outsideOpeningHours('OUTSIDE_OPENING_HOURS');

  final String apiValue;
  const OutsideBusinessHoursReason(this.apiValue);

  static OutsideBusinessHoursReason? fromApi(Object? value) {
    for (final reason in values) {
      if (reason.apiValue == value) return reason;
    }
    return null;
  }
}

/// `SLOT_UNAVAILABLE` (409; 400 legado, D-11): el hueco no está libre (otra
/// cita, fuera del horario del profesional o un bloqueo). Desde 13.04 trae el
/// motivo ([reason]) y, si es el horario del profesional, sus franjas de ese
/// día ([hours], `HH:mm` en hora del negocio; vacía si ese día no trabaja).
/// El texto para el usuario lo arma presentation (`SlotProblemText`).
class SlotUnavailableFailure extends ConflictFailure {
  static const defaultMessage = 'Horario no disponible';

  final SlotUnavailableReason? reason;
  final List<WorkHours> hours;

  const SlotUnavailableFailure({
    String? message,
    super.statusCode,
    super.details,
    super.info,
    this.reason,
    this.hours = const [],
  }) : super(
            message: message ?? defaultMessage,
            code: ApiErrorCode.slotUnavailable);
}

/// `PROFESSIONAL_INACTIVE` (409; 400 legado): el profesional no se puede
/// agendar (inactivo, o empleado sin verificar el email).
class ProfessionalInactiveFailure extends ConflictFailure {
  static const defaultMessage =
      'El profesional no está activo y no puede recibir citas';

  const ProfessionalInactiveFailure({
    String? message,
    super.statusCode,
    super.details,
  }) : super(
            message: message ?? defaultMessage,
            code: ApiErrorCode.professionalInactive);
}

/// `APPOINTMENT_IN_PAST` (400): agendar, o mover a otra fecha, en una hora
/// ya pasada. También la produce `CreateAppointmentUseCase` sin ir al backend.
class AppointmentInPastFailure extends ValidationFailure {
  static const defaultMessage =
      'No se pueden agendar citas en una hora que ya pasó';

  const AppointmentInPastFailure({
    String? message,
    super.statusCode,
    super.details,
  }) : super(
            message: message ?? defaultMessage,
            code: ApiErrorCode.appointmentInPast);
}

/// `INVALID_STATE_TRANSITION` (409): cambio de estado no permitido (p. ej.
/// completar o cancelar una cita ya cancelada o completada).
class InvalidStateTransitionFailure extends ConflictFailure {
  static const defaultMessage =
      'La cita ya no admite ese cambio de estado';

  const InvalidStateTransitionFailure({
    String? message,
    super.statusCode,
    super.details,
  }) : super(
            message: message ?? defaultMessage,
            code: ApiErrorCode.invalidStateTransition);
}

/// `APPOINTMENT_PAID` (409): cancelar una cita con algo pagado sin
/// reembolsar (también un anticipo). Hay que reembolsar antes.
class AppointmentPaidFailure extends ConflictFailure {
  static const defaultMessage =
      'La cita tiene pagos registrados: reembólsalos antes de cancelarla';

  const AppointmentPaidFailure({
    String? message,
    super.statusCode,
    super.details,
  }) : super(
            message: message ?? defaultMessage,
            code: ApiErrorCode.appointmentPaid);
}

/// `send-reminder` respondió `CONFLICT` (409): la cita ya no está pendiente
/// ni confirmada, o el cliente no tiene teléfono. El motivo va en [message].
class ReminderUnavailableFailure extends ConflictFailure {
  static const defaultMessage =
      'No se puede enviar el recordatorio de esta cita';

  const ReminderUnavailableFailure({
    String? message,
    super.statusCode,
    super.details,
  }) : super(message: message ?? defaultMessage, code: ApiErrorCode.conflict);
}

/// Datos de la cita fuera de las reglas del backend (sin servicios,
/// repetidos, sin cliente o profesional). La producen los use cases antes de
/// llamar al backend.
class InvalidAppointmentDataFailure extends ValidationFailure {
  const InvalidAppointmentDataFailure({super.message});
}

/// `SERVICE_NOT_OFFERED_BY_PROFESSIONAL` (409, 7.03): el empleado no tiene
/// asignado (y activo) alguno de los servicios elegidos. El Owner como
/// profesional hace todos. Al agendar, mover o pedir horas libres.
class ServiceNotOfferedFailure extends ConflictFailure {
  static const defaultMessage =
      'El profesional no realiza uno o más de los servicios elegidos';

  const ServiceNotOfferedFailure({
    String? message,
    super.statusCode,
    super.details,
  }) : super(
            message: message ?? defaultMessage,
            code: ApiErrorCode.serviceNotOfferedByProfessional);
}

/// `APPOINTMENT_NOT_STARTED` (409, 7.03): completar una cita cuya hora de
/// inicio aún no llega.
class AppointmentNotStartedFailure extends ConflictFailure {
  static const defaultMessage =
      'No se puede completar una cita que aún no ha empezado';

  const AppointmentNotStartedFailure({
    String? message,
    super.statusCode,
    super.details,
  }) : super(
            message: message ?? defaultMessage,
            code: ApiErrorCode.appointmentNotStarted);
}

/// `OUTSIDE_BUSINESS_HOURS` (409, 8.01): agendar o mover fuera del horario
/// de apertura del negocio (si lo tiene configurado). Desde 13.04 trae el
/// motivo ([reason]) y las franjas de apertura de ese día ([hours]).
class OutsideBusinessHoursFailure extends ConflictFailure {
  static const defaultMessage = 'El negocio está cerrado a esa hora';

  final OutsideBusinessHoursReason? reason;
  final List<WorkHours> hours;

  const OutsideBusinessHoursFailure({
    String? message,
    super.statusCode,
    super.details,
    super.info,
    this.reason,
    this.hours = const [],
  }) : super(
            message: message ?? defaultMessage,
            code: ApiErrorCode.outsideBusinessHours);
}

/// `SERVICE_INACTIVE` (409, 2026-10-31): agendar, pedir horas libres o
/// añadir a una cita un servicio desactivado.
class ServiceInactiveFailure extends ConflictFailure {
  static const defaultMessage =
      'Uno de los servicios elegidos está desactivado';

  const ServiceInactiveFailure({
    String? message,
    super.statusCode,
    super.details,
  }) : super(
            message: message ?? defaultMessage,
            code: ApiErrorCode.serviceInactive);
}
