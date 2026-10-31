import 'package:login_signup/core/database/app_database.dart';
import 'package:login_signup/core/database/document_store.dart';
import 'package:login_signup/core/database/shared_documents.dart';
import 'package:login_signup/core/sync/document_sync_handler.dart';
import 'package:login_signup/core/sync/outbox_store.dart';
import 'package:login_signup/core/utils/business_time_zone.dart';
import 'package:login_signup/core/utils/json_read.dart';

/// Citas sin conexión (10.02b): operaciones `appointment.*` y cómo se
/// aplican en la base local. Lo usan el repositorio al escribir y el motor
/// al reaplicar lo pendiente tras una bajada (mismo código).
abstract final class AppointmentsSync {
  static const create = 'appointment.create';
  static const update = 'appointment.update';
  static const cancel = 'appointment.cancel';
  static const complete = 'appointment.complete';

  static final kind = SharedDocs.appointments;

  /// Bloqueos de tiempo (feed `time_block`, solo bajada): ocupan la agenda
  /// del profesional (horas libres sin conexión).
  static final timeBlocks = DocumentKind('time_block',
      ref1: (d) => JsonRead.asOptionalString(
          d['user'] is Map ? (d['user'] as Map)['id'] : d['user']),
      at: (d) => d['start_datetime']);

  static Future<void> apply(AppDatabase db, OutboxEntry entry) async {
    final id = entry.entityId;
    if (id == null) return;
    await DocumentStore.keepServerCopy(db, kind.entity, id);
    final p = entry.payload;
    final current = await DocumentStore.get(db, kind.entity, id) ?? {};
    final changes = <String, dynamic>{'updated_at': entry.clientTime};

    switch (entry.type) {
      case create:
        changes.addAll({
          'id': id,
          'status': 'PENDING',
          'payment_status': 'PENDING',
          'reminderSent': false,
          'reminderSentAt': null,
          'source': 'APP',
          'needsReschedule': false,
          'syncConflict': null,
          'created_at': entry.clientTime,
        });
        await _applyFields(db, current, p, changes, moving: true);
      case update:
        await _applyFields(db, current, p, changes,
            moving: p.containsKey('date'));
      case cancel:
        changes['status'] = 'CANCELLED';
        if (p['cancellation_reason'] != null) {
          changes['cancellation_reason'] = p['cancellation_reason'];
        }
      case complete:
        changes['status'] = 'COMPLETED';
    }
    await DocumentStore.merge(db, kind, id, changes);
  }

  /// Campos del DTO (`client_id`, `professional_id`, `service_ids`, `date`,
  /// `notes`) → forma de la API, con los datos locales de cliente,
  /// profesional y servicios.
  static Future<void> _applyFields(
    AppDatabase db,
    Map<String, dynamic> current,
    Map<String, dynamic> p,
    Map<String, dynamic> changes, {
    required bool moving,
  }) async {
    if (p['client_id'] case final String clientId) {
      changes['client'] = await _client(db, clientId);
    }
    if (p['professional_id'] case final String professionalId) {
      changes['professionalId'] = professionalId;
      changes['professional'] = await _professional(db, professionalId);
    }
    if (p['service_ids'] case final List<dynamic> ids) {
      final kept = {
        for (final s in JsonRead.asMapList(current['services']))
          s['id']: s['appointment_price'] ?? s['price'],
      };
      final services = <Map<String, dynamic>>[];
      for (final serviceId in ids) {
        final service =
            await DocumentStore.get(db, 'services', serviceId.toString()) ??
                {'id': serviceId.toString(), 'name': '', 'price': 0};
        services.add({
          ...service,
          // Los que la cita ya tenía conservan su precio (2.29).
          'appointment_price': kept[serviceId] ?? service['price'],
        });
      }
      changes['services'] = services;
      final cents = services.fold<int>(
          0,
          (sum, s) =>
              sum + (JsonRead.asDouble(s['appointment_price']) * 100).round());
      changes['total_price'] = (cents / 100).toStringAsFixed(2);
    }
    if (p.containsKey('date')) {
      changes['date'] = p['date'];
      // Mover toma la zona ACTUAL del negocio (6.03) y limpia el conflicto
      // y el recordatorio manual (2.18).
      changes['timezone'] = BusinessTimeZone.current;
    }
    if (moving) {
      changes['needsReschedule'] = false;
      changes['syncConflict'] = null;
      changes['reminderSent'] = false;
      changes['reminderSentAt'] = null;
    }
    if (p.containsKey('notes')) changes['notes'] = p['notes'];
  }

  static Future<Map<String, dynamic>> _client(
      AppDatabase db, String id) async {
    final row = await (db.select(db.localClients)
          ..where((c) => c.id.equals(id)))
        .getSingleOrNull();
    return {
      'id': id,
      'name': row?.name ?? '',
      'lastname': row?.lastname ?? '',
      'phone': row?.phone,
    };
  }

  static Future<Map<String, dynamic>> _professional(
      AppDatabase db, String id) async {
    final user = await DocumentStore.get(db, SharedDocs.users.entity, id);
    return {
      'id': id,
      'name': user?['name'] ?? '',
      'lastname': user?['lastname'] ?? '',
    };
  }

  /// El cliente [fromId] se fusionó con [toId]: las citas que lo nombran
  /// pasan al otro.
  static Future<void> remap(
      AppDatabase db, String entity, String fromId, String toId) async {
    if (entity != 'clients') return;
    for (final doc
        in await DocumentStore.list(db, kind.entity, ref2: fromId)) {
      await DocumentStore.put(db, kind, doc['id'] as String,
          {...doc, 'client': await _client(db, toId)});
    }
  }

  static List<DocumentSyncHandler> handlers() => [
        DocumentSyncHandler(kind, applyLocal: apply, onRemap: remap),
        DocumentSyncHandler(timeBlocks),
      ];
}
