import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/network/safe_call.dart';
import 'package:login_signup/features/appointments/data/datasources/appointments_remote_datasource.dart';
import 'package:login_signup/features/appointments/domain/entities/appointment_changes.dart';
import 'package:login_signup/features/appointments/domain/entities/appointment_entity.dart';
import 'package:login_signup/features/appointments/domain/entities/appointment_queries.dart';
import 'package:login_signup/features/appointments/domain/entities/manual_reminder.dart';
import 'package:login_signup/features/appointments/domain/entities/new_appointment.dart';
import 'package:login_signup/features/appointments/domain/failures/appointment_failures.dart';
import 'package:login_signup/features/appointments/domain/repositories/appointments_repository.dart';
import 'package:login_signup/features/subscriptions/domain/failures/subscription_failures.dart'
    show refineSubscriptionFailure;

class AppointmentsRepositoryImpl implements AppointmentsRepository {
  final AppointmentsRemoteDataSource _remote;

  AppointmentsRepositoryImpl(this._remote);

  /// `GET /appointments` filtra por rango (2.34); aquí se vuelve a filtrar
  /// por instante (inicio dentro de [range]) y se ordenan.
  @override
  Future<Either<Failure, List<AppointmentEntity>>> getAppointments(
          AppointmentsRange range) =>
      safeCall(() async {
        final appointments = (await _remote.getAppointments(range))
            .map((m) => m.toEntity())
            .where((a) => range.contains(a.startInstant))
            .toList()
          ..sort((a, b) => a.startInstant.compareTo(b.startInstant));
        return appointments;
      }, refine: _refine);

  @override
  Future<Either<Failure, AppointmentEntity>> getAppointment(String id) =>
      safeCall(() async => (await _remote.getAppointment(id)).toEntity(),
          refine: _refine);

  @override
  Future<Either<Failure, AppointmentEntity>> createAppointment(
          NewAppointment appointment) =>
      safeCall(
          () async => (await _remote.createAppointment(appointment)).toEntity(),
          refine: _refine);

  @override
  Future<Either<Failure, AppointmentEntity>> updateAppointment(
          String id, AppointmentChanges changes) =>
      safeCall(
          () async =>
              (await _remote.updateAppointment(id, changes)).toEntity(),
          refine: _refine);

  @override
  Future<Either<Failure, AppointmentEntity>> cancelAppointment(String id,
          {String? reason}) =>
      safeCall(
          () async =>
              (await _remote.cancelAppointment(id, reason: reason)).toEntity(),
          refine: _refine);

  @override
  Future<Either<Failure, AppointmentEntity>> completeAppointment(String id) =>
      safeCall(() async => (await _remote.completeAppointment(id)).toEntity(),
          refine: _refine);

  @override
  Future<Either<Failure, List<DateTime>>> getAvailableSlots(
          AvailableSlotsQuery query) =>
      safeCall(() => _remote.getAvailableSlots(query), refine: _refine);

  /// Aquí `CONFLICT` solo significa "no se puede recordar esta cita" (estado
  /// o cliente sin teléfono): el texto del backend dice cuál.
  @override
  Future<Either<Failure, ManualReminder>> prepareReminder(String id) =>
      safeCall(() => _remote.prepareReminder(id),
          refine: (failure) => failure.code == ApiErrorCode.conflict
              ? ReminderUnavailableFailure(
                  message: failure.message,
                  statusCode: failure.statusCode,
                  details: failure.details)
              : _refine(failure));

  @override
  Future<Either<Failure, DateTime>> markReminderSent(String id) =>
      safeCall(() => _remote.markReminderSent(id), refine: _refine);

  /// Failures propios por `code` (nunca por texto ni por HTTP: el HTTP
  /// legado 400 de D-11 no cambia el resultado).
  static Failure _refine(Failure failure) => switch (failure.code) {
        ApiErrorCode.slotUnavailable => SlotUnavailableFailure(
            message: failure.message,
            statusCode: failure.statusCode,
            details: failure.details),
        ApiErrorCode.professionalInactive => ProfessionalInactiveFailure(
            message: failure.message,
            statusCode: failure.statusCode,
            details: failure.details),
        ApiErrorCode.appointmentInPast => AppointmentInPastFailure(
            message: failure.message,
            statusCode: failure.statusCode,
            details: failure.details),
        ApiErrorCode.invalidStateTransition => InvalidStateTransitionFailure(
            message: failure.message,
            statusCode: failure.statusCode,
            details: failure.details),
        ApiErrorCode.appointmentPaid => AppointmentPaidFailure(
            message: failure.message,
            statusCode: failure.statusCode,
            details: failure.details),
        _ => refineSubscriptionFailure(failure),
      };
}
