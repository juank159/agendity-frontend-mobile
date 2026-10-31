import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/network/safe_call.dart';
import 'package:login_signup/core/database/document_store.dart';
import 'package:login_signup/core/sync/offline_store.dart';
import 'package:login_signup/core/utils/date_codec.dart';
import 'package:login_signup/core/utils/business_time_zone.dart';
import 'package:login_signup/features/appointments/data/datasources/appointments_local_datasource.dart';
import 'package:login_signup/features/appointments/data/models/appointment_model.dart';
import 'package:login_signup/features/appointments/data/sync/appointments_sync.dart';
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

/// Citas sin conexión (10.02b, D-18): se leen de la base local y agendar,
/// editar, mover, cancelar y completar se guardan en local + bandeja
/// (`appointment.*`). Las reglas que se pueden ver en local (estado, pagos,
/// ya empezó) se avisan al momento; agenda, cupo y horario los decide el
/// servidor al sincronizar (una cita sin hueco vuelve guardada y marcada
/// para mover, `needsReschedule`). Las horas libres se piden al servidor y,
/// sin conexión, se calculan en local con las mismas reglas. Los
/// recordatorios manuales necesitan conexión.
class AppointmentsRepositoryImpl implements AppointmentsRepository {
  final AppointmentsRemoteDataSource _remote;
  final OfflineStore _store;
  final AppointmentsLocalDataSource _local;

  AppointmentsRepositoryImpl(
    this._remote, {
    required OfflineStore store,
    AppointmentsLocalDataSource local = const AppointmentsLocalDataSource(),
  })  : _store = store,
        _local = local;

  static const _entity = 'appointments';

  @override
  Future<Either<Failure, List<AppointmentEntity>>> getAppointments(
          AppointmentsRange range) =>
      safeCall(() async => _local.appointments(await _store.database(), range));

  @override
  Future<Either<Failure, List<AppointmentEntity>>>
      getAppointmentsToReschedule() => safeCall(
          () async => _local.toReschedule(await _store.database()));

  @override
  Future<Either<Failure, AppointmentEntity>> getAppointment(String id) =>
      OfflineStore.guard(() async {
        final found = await _local.appointment(await _store.database(), id);
        return found == null ? const Left(NotFoundFailure()) : Right(found);
      });

  @override
  Future<Either<Failure, AppointmentEntity>> createAppointment(
          NewAppointment appointment) =>
      OfflineStore.guard(() async {
        final id = _store.newId();
        await _write(AppointmentsSync.create, id,
            NewAppointmentModel.toJson(appointment));
        return getAppointment(id);
      });

  @override
  Future<Either<Failure, AppointmentEntity>> updateAppointment(
          String id, AppointmentChanges changes) =>
      _withCurrent(id, (current) async {
        if (changes.isEmpty) return Right(current);
        await _write(
            AppointmentsSync.update, id, AppointmentChangesModel.toJson(changes));
        return getAppointment(id);
      });

  @override
  Future<Either<Failure, AppointmentEntity>> cancelAppointment(String id,
          {String? reason}) =>
      _withCurrent(id, (current) async {
        if (current.isCancelled) return Right(current);
        if (!(current.isPending || current.isConfirmed)) {
          return const Left(InvalidStateTransitionFailure());
        }
        if (current.paymentStatus.hasNetPayments) {
          return const Left(AppointmentPaidFailure());
        }
        await _write(AppointmentsSync.cancel, id,
            {if (reason != null) 'cancellation_reason': reason});
        return getAppointment(id);
      });

  @override
  Future<Either<Failure, AppointmentEntity>> completeAppointment(String id) =>
      _withCurrent(id, (current) async {
        if (current.isCompleted) return Right(current);
        if (!current.canComplete) {
          return const Left(InvalidStateTransitionFailure());
        }
        if (!current.hasStartedAt(BusinessTimeZone.now())) {
          return const Left(AppointmentNotStartedFailure());
        }
        await _write(AppointmentsSync.complete, id, const {});
        return getAppointment(id);
      });

  /// Con conexión, el servidor; sin ella, el cálculo local.
  @override
  Future<Either<Failure, List<DateTime>>> getAvailableSlots(
      AvailableSlotsQuery query) async {
    final online =
        await safeCall(() => _remote.getAvailableSlots(query), refine: _refine);
    final failure = online.fold<Failure?>((f) => f, (_) => null);
    if (failure is! NetworkFailure) return online;
    return OfflineStore.guard(() async {
      final (problem, slots) =
          await _local.freeSlots(await _store.database(), query);
      return problem == null ? Right(slots) : Left(problem);
    });
  }

  Future<Either<Failure, AppointmentEntity>> _withCurrent(
          String id,
          Future<Either<Failure, AppointmentEntity>> Function(
                  AppointmentEntity current)
              body) =>
      OfflineStore.guard(() async {
        final current = await _local.appointment(await _store.database(), id);
        if (current == null) return const Left(NotFoundFailure());
        return body(current);
      });

  Future<void> _write(String type, String id, Map<String, dynamic> payload) =>
      _store.write((db, sink) async {
        final entry = await sink.add(
            type: type, entity: _entity, entityId: id, payload: payload);
        await AppointmentsSync.apply(db, entry);
      });

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

  /// Con conexión; la marca queda también en local (la bajada la confirma).
  @override
  Future<Either<Failure, DateTime>> markReminderSent(String id) =>
      safeCall(() async {
        final sentAt = await _remote.markReminderSent(id);
        final db = await _store.database();
        if (await DocumentStore.get(db, _entity, id) != null) {
          await DocumentStore.merge(db, AppointmentsSync.kind, id, {
            'reminderSent': true,
            'reminderSentAt': DateCodec.encode(sentAt),
          });
        }
        return sentAt;
      }, refine: _refine);

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
        ApiErrorCode.serviceNotOfferedByProfessional =>
          ServiceNotOfferedFailure(
              message: failure.message,
              statusCode: failure.statusCode,
              details: failure.details),
        ApiErrorCode.appointmentNotStarted => AppointmentNotStartedFailure(
            message: failure.message,
            statusCode: failure.statusCode,
            details: failure.details),
        ApiErrorCode.serviceInactive => ServiceInactiveFailure(
            message: failure.message,
            statusCode: failure.statusCode,
            details: failure.details),
        ApiErrorCode.outsideBusinessHours => OutsideBusinessHoursFailure(
            message: failure.message,
            statusCode: failure.statusCode,
            details: failure.details),
        _ => refineSubscriptionFailure(failure),
      };
}
