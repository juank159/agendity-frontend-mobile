import 'package:login_signup/core/database/app_database.dart';
import 'package:login_signup/core/database/document_store.dart';
import 'package:login_signup/core/database/shared_documents.dart';
import 'package:login_signup/core/utils/business_time_zone.dart';
import 'package:login_signup/core/utils/date_codec.dart';
import 'package:login_signup/core/utils/json_read.dart';
import 'package:login_signup/features/appointments/data/models/appointment_model.dart';
import 'package:login_signup/features/appointments/data/sync/appointments_sync.dart';
import 'package:login_signup/features/appointments/domain/entities/appointment_entity.dart';
import 'package:login_signup/features/appointments/domain/entities/appointment_queries.dart';
import 'package:login_signup/features/appointments/domain/failures/appointment_failures.dart';
import 'package:login_signup/features/appointments/domain/usecases/free_slots.dart';
import 'package:login_signup/core/errors/failures.dart';

/// Citas y agenda en la base local (10.02b).
class AppointmentsLocalDataSource {
  const AppointmentsLocalDataSource();

  /// Citas que empiezan en [range], por instante.
  Future<List<AppointmentEntity>> appointments(
      AppDatabase db, AppointmentsRange range) async {
    final docs = await DocumentStore.list(db, AppointmentsSync.kind.entity,
        from: BusinessTimeZone.toInstant(range.start),
        to: BusinessTimeZone.toInstant(range.end));
    return [
      for (final doc in docs)
        if (_entity(doc) case final appointment?) appointment,
    ]..sort((a, b) => a.startInstant.compareTo(b.startInstant));
  }

  Future<AppointmentEntity?> appointment(AppDatabase db, String id) async {
    final doc = await DocumentStore.get(db, AppointmentsSync.kind.entity, id);
    return doc == null ? null : _entity(doc);
  }

  static AppointmentEntity? _entity(Map<String, dynamic> doc) {
    try {
      return AppointmentModel.fromJson(doc).toEntity();
    } on FormatException {
      return null;
    }
  }

  /// Horas libres sin conexión (mismas reglas que el backend, [FreeSlots]).
  /// Devuelve el failure que daría el servidor si el profesional o un
  /// servicio no se pueden agendar.
  Future<(Failure?, List<DateTime>)> freeSlots(
      AppDatabase db, AvailableSlotsQuery query) async {
    final user =
        await DocumentStore.get(db, SharedDocs.users.entity, query.professionalId);
    if (user == null) return (const NotFoundFailure(), const <DateTime>[]);
    if (!JsonRead.asBool(user['isActive'], fallback: true) ||
        JsonRead.asOptionalString(user['deletedAt']) != null) {
      return (const ProfessionalInactiveFailure(), const <DateTime>[]);
    }

    // Servicios: activos y que el profesional hace (el Owner, todos).
    final isOwner = SharedDocs.isOwner(user);
    final assigned = {
      for (final row in await DocumentStore.list(
          db, SharedDocs.userServices.entity,
          ref1: query.professionalId))
        if (JsonRead.asBool(row['isActive'], fallback: true)) row['serviceId'],
    };
    var duration = 0;
    for (final serviceId in query.serviceIds) {
      final service = await DocumentStore.get(db, 'services', serviceId);
      if (service == null) return (const NotFoundFailure(), const <DateTime>[]);
      if (!JsonRead.asBool(service['isActive'], fallback: true)) {
        return (const ServiceInactiveFailure(), const <DateTime>[]);
      }
      if (!isOwner && !assigned.contains(serviceId)) {
        return (const ServiceNotOfferedFailure(), const <DateTime>[]);
      }
      final minutes = JsonRead.asInt(service['duration']);
      duration += minutes > 0 ? minutes : 30;
    }

    final day = DateTime(query.day.year, query.day.month, query.day.day);
    final nextDay = DateTime(day.year, day.month, day.day + 1);
    // Ocupado: citas del profesional que no están canceladas ni para mover
    // (del día anterior también, por si cruzan la medianoche) y bloqueos.
    final busy = <BusyInterval>[];
    final dayBefore = DateTime(day.year, day.month, day.day - 1);
    for (final doc in await DocumentStore.list(db, AppointmentsSync.kind.entity,
        ref1: query.professionalId,
        from: BusinessTimeZone.toInstant(dayBefore),
        to: BusinessTimeZone.toInstant(nextDay))) {
      final appointment = _entity(doc);
      if (appointment == null || !appointment.blocksSlot) continue;
      final start = BusinessTimeZone.toWallClock(appointment.startInstant);
      busy.add(BusyInterval(start, start.add(appointment.duration)));
    }
    for (final block in await DocumentStore.list(
        db, AppointmentsSync.timeBlocks.entity,
        ref1: query.professionalId)) {
      final start = DateCodec.tryDecode(block['start_datetime']);
      final end = DateCodec.tryDecode(block['end_datetime']);
      if (start != null && end != null) busy.add(BusyInterval(start, end));
    }

    final schedules = [
      for (final row in await DocumentStore.list(
          db, SharedDocs.schedules.entity,
          ref1: query.professionalId))
        if (JsonRead.asBool(row['is_available'], fallback: true))
          if (_window(row['day_of_week'], row['start_time'], row['end_time'])
              case final w?)
            w,
    ];
    final settings =
        (await DocumentStore.list(db, SharedDocs.businessSettings.entity))
            .firstOrNull;
    final opening = settings?['opening_hours'];
    final businessWindows = opening is List
        ? [
            for (final row in JsonRead.asMapList(opening))
              if (_window(row['day_of_week'], row['start_time'],
                  row['end_time']) case final w?)
                w,
          ]
        : null;

    return (
      null,
      FreeSlots.compute(
        day: day,
        durationMinutes: duration,
        stepMinutes: query.stepMinutes ?? 15,
        professionalWindows: schedules,
        businessWindows: businessWindows,
        busy: busy,
        now: BusinessTimeZone.now(),
      ),
    );
  }

  static ScheduleWindow? _window(Object? day, Object? start, Object? end) {
    final from = ScheduleWindow.minutesOf(JsonRead.asString(start));
    final to = ScheduleWindow.minutesOf(JsonRead.asString(end));
    final weekday = JsonRead.asInt(day);
    if (from == null || to == null || weekday < 1 || weekday > 7) return null;
    return ScheduleWindow(weekday, from, to);
  }
}
