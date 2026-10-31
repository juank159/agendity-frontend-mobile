import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/features/appointments/domain/entities/appointment_changes.dart';
import 'package:login_signup/features/appointments/domain/entities/appointment_entity.dart';
import 'package:login_signup/features/appointments/domain/entities/appointment_queries.dart';
import 'package:login_signup/features/appointments/domain/entities/manual_reminder.dart';
import 'package:login_signup/features/appointments/domain/entities/new_appointment.dart';

/// Citas (`/appointments`). Owner: todas las del negocio; Employee: solo
/// las suyas (el backend filtra; una ajena da `NotFoundFailure`).
///
/// Failures propios (`appointment_failures.dart`), decididos por `code`:
/// `SlotUnavailableFailure`, `ProfessionalInactiveFailure`,
/// `AppointmentInPastFailure`, `InvalidStateTransitionFailure`,
/// `AppointmentPaidFailure`, `TrialLimitReachedFailure`,
/// `SubscriptionInactiveFailure` y `ReminderUnavailableFailure`.
abstract class AppointmentsRepository {
  /// Citas que empiezan en [range], ordenadas por fecha.
  Future<Either<Failure, List<AppointmentEntity>>> getAppointments(
      AppointmentsRange range);

  /// Citas guardadas con conflicto al sincronizar que hay que **mover**
  /// (`needsReschedule`, 10.01b), sin las canceladas, por fecha. Owner:
  /// todas; Employee: las suyas (solo baja lo suyo).
  Future<Either<Failure, List<AppointmentEntity>>> getAppointmentsToReschedule();

  /// Una cita (p. ej. para refrescarla tras registrar un pago).
  Future<Either<Failure, AppointmentEntity>> getAppointment(String id);

  /// Agenda una cita y consume el cupo del plan (trial o suscripción) en la
  /// misma transacción: `TrialLimitReachedFailure`/`SubscriptionInactiveFailure`
  /// si no queda. Employee: solo para sí mismo (`ForbiddenFailure`).
  Future<Either<Failure, AppointmentEntity>> createAppointment(
      NewAppointment appointment);

  /// Cambia solo los campos de [changes] (solo Owner). No consume cupo.
  Future<Either<Failure, AppointmentEntity>> updateAppointment(
      String id, AppointmentChanges changes);

  /// `PENDING|CONFIRMED → CANCELLED`. Con algo pagado: `AppointmentPaidFailure`.
  Future<Either<Failure, AppointmentEntity>> cancelAppointment(String id,
      {String? reason});

  /// `PENDING|CONFIRMED → COMPLETED` (también sin pagar).
  Future<Either<Failure, AppointmentEntity>> completeAppointment(String id);

  /// Inicios libres del profesional ese día para esos servicios (misma regla
  /// que al agendar; oculta las horas pasadas de hoy).
  Future<Either<Failure, List<DateTime>>> getAvailableSlots(
      AvailableSlotsQuery query);

  /// Teléfono, texto y enlace `wa.me` del recordatorio manual. No envía ni
  /// marca nada.
  Future<Either<Failure, ManualReminder>> prepareReminder(String id);

  /// Registra que se envió el recordatorio manual; devuelve la hora del
  /// primer envío.
  Future<Either<Failure, DateTime>> markReminderSent(String id);
}
