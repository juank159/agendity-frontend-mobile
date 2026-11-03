import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/network/safe_call.dart';
import 'package:login_signup/core/database/document_store.dart';
import 'package:login_signup/core/sync/offline_store.dart';
import 'package:login_signup/core/sync/outbox_store.dart';
import 'package:login_signup/core/utils/date_codec.dart';
import 'package:login_signup/core/utils/business_time_zone.dart';
import 'package:login_signup/core/utils/json_read.dart';
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

/// Citas (10.02b y 13.05, D-18): se leen de la base local.
///
/// - **Agendar y mover con conexión** (13.05, D-25) va directo al servidor
///   (`POST /appointments`, `PATCH /appointments/:id` si cambian fecha,
///   profesional o servicios): es estricto, así que un choque
///   (`SLOT_UNAVAILABLE`, `OUTSIDE_BUSINESS_HOURS`…) vuelve como failure al
///   formulario y no se guarda nada; si sale bien, la cita queda en local con
///   la forma de la API, como si viniera de la bajada.
/// - **Sin conexión** (la última sincronización falló por red, o la llamada
///   da un error de red/timeout o 502–504), y para cancelar, completar o
///   cambiar solo notas o cliente: local + bandeja (`appointment.*`). Las
///   reglas que se pueden ver en local (estado, pagos, ya empezó) se avisan
///   al momento; agenda, cupo y horario los decide el servidor al
///   sincronizar (una cita sin hueco vuelve guardada y marcada para mover,
///   `needsReschedule`).
/// - Mientras la cita (o su cliente o servicios) tenga algo en la bandeja,
///   sus cambios siguen por la bandeja para no alterar el orden.
///
/// Las horas libres se piden al servidor y, sin conexión, se calculan en
/// local con las mismas reglas. Los recordatorios manuales necesitan
/// conexión.
class AppointmentsRepositoryImpl implements AppointmentsRepository {
  final AppointmentsRemoteDataSource _remote;
  final OfflineStore _store;
  final AppointmentsLocalDataSource _local;

  /// ¿Hay conexión según la última sincronización (`SyncEngine.current
  /// .online`)? `null` = sin camino directo: todo por la bandeja.
  final bool Function()? _isOnline;

  /// Sube lo pendiente de la bandeja antes de ir directo
  /// (`SyncEngine.syncNow`), para que el servidor vea los cambios en orden
  /// (p. ej. el cliente recién creado desde el formulario de la cita).
  final Future<void> Function()? _flush;

  AppointmentsRepositoryImpl(
    this._remote, {
    required OfflineStore store,
    AppointmentsLocalDataSource local = const AppointmentsLocalDataSource(),
    bool Function()? isOnline,
    Future<void> Function()? flush,
  })  : _store = store,
        _local = local,
        _isOnline = isOnline,
        _flush = flush;

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
        final db = await _store.database();
        // Un cliente creado sin conexión que el servidor fusionó con otro.
        final clientId =
            await OutboxStore.resolveId(db, 'clients', appointment.clientId);
        final payload = {
          ...NewAppointmentModel.toJson(appointment),
          'client_id': clientId,
        };
        final direct = await _tryDirect(
          id,
          dependsOn: [
            ('clients', clientId),
            for (final serviceId in appointment.serviceIds)
              ('services', serviceId),
          ],
          send: () => _remote.createAppointment(id, payload),
        );
        if (direct != null) return direct;
        await _write(AppointmentsSync.create, id, payload);
        return getAppointment(id);
      });

  @override
  Future<Either<Failure, AppointmentEntity>> updateAppointment(
          String id, AppointmentChanges changes) =>
      _withCurrent(id, (current) async {
        if (changes.isEmpty) return Right(current);
        final payload = AppointmentChangesModel.toJson(changes);
        if (changes.touchesSlot) {
          final direct = await _tryDirect(
            id,
            dependsOn: [
              if (changes.clientId case final clientId?) ('clients', clientId),
              for (final serviceId in changes.serviceIds ?? const <String>[])
                ('services', serviceId),
            ],
            send: () => _remote.updateAppointment(id, payload),
          );
          if (direct != null) return direct;
        }
        await _write(AppointmentsSync.update, id, payload);
        return getAppointment(id);
      });

  /// Camino directo (13.05). `null` = va por la bandeja: sin conexión
  /// conocida, con algo de esta cita (o de lo que nombra) aún en la bandeja,
  /// o la llamada no llegó (error de red, timeout, 502–504). Si el servidor
  /// respondió, su resultado manda: un error vuelve tal cual (nada en local)
  /// y un éxito se guarda como la versión del servidor.
  Future<Either<Failure, AppointmentEntity>?> _tryDirect(
    String id, {
    required List<(String, String)> dependsOn,
    required Future<Map<String, dynamic>> Function() send,
  }) async {
    final isOnline = _isOnline;
    if (isOnline == null || !isOnline()) return null;
    final db = await _store.database();
    if ((await OutboxStore.counts(db)).pending > 0) {
      try {
        await _flush?.call();
      } catch (_) {
        // Sin subir: lo de abajo decide (seguirá por la bandeja).
      }
      if (!isOnline()) return null;
    }
    for (final (entity, entityId) in [(_entity, id), ...dependsOn]) {
      if (await OutboxStore.hasEntriesFor(db, entity, entityId)) return null;
    }

    final result = await safeCall(send, refine: _refine);
    final failure = result.fold<Failure?>((f) => f, (_) => null);
    if (failure != null) return _didNotReach(failure) ? null : Left(failure);

    final saved = result.getOrElse(() => const {});
    await _store.write((db, _) => AppointmentsSync.saveServerVersion(
        db, JsonRead.asOptionalString(saved['id']) ?? id, saved));
    return getAppointment(id);
  }

  /// La petición no llegó o no se sabe si llegó: no se pierde (bandeja, D-18).
  static bool _didNotReach(Failure failure) =>
      failure is NetworkFailure ||
      (failure is ServerFailure &&
          const {502, 503, 504}.contains(failure.statusCode));

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
            details: failure.details,
            info: failure.info,
            reason: SlotUnavailableReason.fromApi(failure.info['reason']),
            hours: ScheduleProblemModel.hours(failure.info['hours'])),
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
            details: failure.details,
            info: failure.info,
            reason:
                OutsideBusinessHoursReason.fromApi(failure.info['reason']),
            hours: ScheduleProblemModel.hours(failure.info['hours'])),
        _ => refineSubscriptionFailure(failure),
      };
}
