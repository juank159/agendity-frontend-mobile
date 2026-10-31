import 'package:login_signup/core/errors/failures.dart';

export 'package:login_signup/features/subscriptions/domain/failures/subscription_failures.dart'
    show TrialLimitReachedFailure, SubscriptionInactiveFailure;

/// `SLOT_UNAVAILABLE` (409; 400 legado, D-11): el hueco no está libre (otra
/// cita, fuera del horario del profesional o un bloqueo).
class SlotUnavailableFailure extends ConflictFailure {
  static const defaultMessage = 'Horario no disponible';

  const SlotUnavailableFailure({
    String? message,
    super.statusCode,
    super.details,
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
/// de apertura del negocio (si lo tiene configurado).
class OutsideBusinessHoursFailure extends ConflictFailure {
  static const defaultMessage = 'El negocio está cerrado a esa hora';

  const OutsideBusinessHoursFailure({
    String? message,
    super.statusCode,
    super.details,
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
