import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/features/appointments/domain/entities/new_appointment.dart';
import 'package:login_signup/features/appointments/domain/failures/appointment_failures.dart';

/// Reglas del DTO de citas del backend que se pueden comprobar sin ir al
/// servidor (`CreateAppointmentDto`, `CancelAppointmentDto`,
/// `AvailableSlotsQueryDto`). Las de agenda y cupo las decide el backend.
abstract final class AppointmentRules {
  static const maxCancellationReasonLength = 500;

  static const noServicesMessage = 'La cita debe tener al menos un servicio';
  static const repeatedServicesMessage =
      'La cita no puede repetir un servicio';
  static const noClientMessage = 'Elige el cliente de la cita';
  static const noProfessionalMessage = 'Elige el profesional de la cita';

  /// `null` si la lista de servicios es válida (al menos uno, sin repetidos).
  static Failure? checkServices(List<String> serviceIds) {
    if (serviceIds.isEmpty) {
      return const InvalidAppointmentDataFailure(message: noServicesMessage);
    }
    if (serviceIds.toSet().length != serviceIds.length) {
      return const InvalidAppointmentDataFailure(
          message: repeatedServicesMessage);
    }
    return null;
  }

  /// `null` si [appointment] se puede enviar en el instante [now].
  static Failure? checkNew(NewAppointment appointment, DateTime now) {
    if (appointment.clientId.trim().isEmpty) {
      return const InvalidAppointmentDataFailure(message: noClientMessage);
    }
    if (appointment.professionalId.trim().isEmpty) {
      return const InvalidAppointmentDataFailure(
          message: noProfessionalMessage);
    }
    return checkServices(appointment.serviceIds) ??
        checkStart(appointment.start, now);
  }

  /// Solo a futuro (2.21): el mismo criterio que `assertStartNotInPast`.
  static Failure? checkStart(DateTime start, DateTime now) =>
      start.isAfter(now) ? null : const AppointmentInPastFailure();
}
