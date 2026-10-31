import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:login_signup/core/database/app_database.dart';
import 'package:login_signup/core/sync/sync_models.dart';

/// Estado de una operación en la bandeja.
enum OutboxStatus {
  /// Se envía en la próxima sincronización.
  pending,

  /// El servidor la rechazó (dato inválido o no permitido): espera a que el
  /// usuario la corrija ([OutboxStore.retry]) o la descarte.
  rejected,

  /// Conflicto que el servidor no guardó (p. ej. editar algo ya borrado).
  conflict;

  static OutboxStatus fromName(String value) =>
      values.firstWhere((s) => s.name == value, orElse: () => pending);
}

/// Una operación de la bandeja de salida.
class OutboxEntry {
  final int seq;
  final String mutationId;
  final String type;
  final String entity;
  final String? entityId;
  final Map<String, dynamic> payload;
  final String clientTime;
  final OutboxStatus status;
  final String? code;
  final String? message;
  final int attempts;

  const OutboxEntry({
    required this.seq,
    required this.mutationId,
    required this.type,
    required this.entity,
    this.entityId,
    this.payload = const {},
    required this.clientTime,
    this.status = OutboxStatus.pending,
    this.code,
    this.message,
    this.attempts = 0,
  });

  factory OutboxEntry.fromRow(OutboxRow row) => OutboxEntry(
        seq: row.seq,
        mutationId: row.mutationId,
        type: row.type,
        entity: row.entity,
        entityId: row.entityId,
        payload: Map<String, dynamic>.from(jsonDecode(row.payload) as Map),
        clientTime: row.clientTime,
        status: OutboxStatus.fromName(row.status),
        code: row.code,
        message: row.message,
        attempts: row.attempts,
      );

  /// Rechazo que depende del estado del negocio (trial agotado, plan
  /// inactivo): se reintenta solo en cada sincronización, sin tocar el dato
  /// local (D-18: "queda en la bandeja hasta que haya un plan").
  bool get isTransientRejection =>
      status == OutboxStatus.rejected && transientCodes.contains(code);

  static const transientCodes = {
    'TRIAL_LIMIT_REACHED',
    'SUBSCRIPTION_INACTIVE',
  };

  PushMutation toPush() => PushMutation(
        mutationId: mutationId,
        type: type,
        entityId: entityId,
        payload: payload,
        clientTime: clientTime,
      );
}

/// Operaciones sobre la tabla [Outbox]. Nada sale de ella sin un resultado
/// del servidor, salvo que el usuario la descarte ([discard]).
abstract final class OutboxStore {
  static Future<void> enqueue(
    AppDatabase db, {
    required String mutationId,
    required String type,
    required String entity,
    String? entityId,
    Map<String, dynamic> payload = const {},
    required DateTime clientTime,
  }) =>
      db.into(db.outbox).insert(OutboxCompanion.insert(
            mutationId: mutationId,
            type: type,
            entity: entity,
            entityId: Value(entityId),
            payload: Value(jsonEncode(payload)),
            clientTime: clientTime.toUtc().toIso8601String(),
          ));

  /// Lo que se envía, en orden, después de [afterSeq]: las pendientes y los
  /// rechazos transitorios.
  static Future<List<OutboxEntry>> sendable(AppDatabase db,
      {required int afterSeq, required int limit}) async {
    final rows = await (db.select(db.outbox)
          ..where((o) =>
              o.seq.isBiggerThanValue(afterSeq) &
              (o.status.equals(OutboxStatus.pending.name) |
                  (o.status.equals(OutboxStatus.rejected.name) &
                      o.code.isIn(OutboxEntry.transientCodes))))
          ..orderBy([(o) => OrderingTerm.asc(o.seq)])
          ..limit(limit))
        .get();
    return rows.map(OutboxEntry.fromRow).toList();
  }

  static Future<List<OutboxEntry>> all(AppDatabase db) async =>
      (await (db.select(db.outbox)..orderBy([(o) => OrderingTerm.asc(o.seq)]))
              .get())
          .map(OutboxEntry.fromRow)
          .toList();

  /// Pendientes de un registro (para reaplicarlas tras una bajada).
  static Future<List<OutboxEntry>> pendingFor(
      AppDatabase db, String entity, String id) async {
    final rows = await (db.select(db.outbox)
          ..where((o) =>
              o.entity.equals(entity) &
              o.entityId.equals(id) &
              o.status.equals(OutboxStatus.pending.name))
          ..orderBy([(o) => OrderingTerm.asc(o.seq)]))
        .get();
    return rows.map(OutboxEntry.fromRow).toList();
  }

  static Future<int> remove(AppDatabase db, String mutationId) =>
      (db.delete(db.outbox)..where((o) => o.mutationId.equals(mutationId)))
          .go();

  static Future<void> mark(AppDatabase db, String mutationId,
          OutboxStatus status, {String? code, String? message}) =>
      (db.update(db.outbox)..where((o) => o.mutationId.equals(mutationId)))
          .write(OutboxCompanion(
        status: Value(status.name),
        code: Value(code),
        message: Value(message),
      ));

  static Future<void> countAttempt(AppDatabase db, String mutationId) =>
      db.customUpdate(
        'UPDATE outbox SET attempts = attempts + 1 WHERE mutation_id = ?',
        variables: [Variable.withString(mutationId)],
        updates: {db.outbox},
      );

  /// El usuario corrigió (o quiere reintentar) una rechazada o en conflicto:
  /// vuelve a pendiente, con [payload] nuevo si lo hay. Mismo `mutation_id`:
  /// si el servidor ya la resolvió, devuelve el mismo resultado; para un
  /// dato corregido se crea una mutación nueva (lo hace el repositorio).
  static Future<void> retry(AppDatabase db, String mutationId) =>
      (db.update(db.outbox)..where((o) => o.mutationId.equals(mutationId)))
          .write(const OutboxCompanion(
        status: Value('pending'),
        code: Value(null),
        message: Value(null),
      ));

  /// Decisión explícita del usuario: renunciar a una operación.
  static Future<int> discard(AppDatabase db, String mutationId) =>
      remove(db, mutationId);

  /// Un id local pasó a ser otro (fusión): se cambia en `entity_id` y en
  /// cualquier valor del payload que lo nombre (p. ej. `client_id`).
  static Future<void> remapIds(
      AppDatabase db, String fromId, String toId) async {
    for (final entry in await all(db)) {
      final payload = _replace(entry.payload, fromId, toId);
      final changedPayload = jsonEncode(payload) != jsonEncode(entry.payload);
      if (entry.entityId != fromId && !changedPayload) continue;
      await (db.update(db.outbox)
            ..where((o) => o.mutationId.equals(entry.mutationId)))
          .write(OutboxCompanion(
        entityId: Value(entry.entityId == fromId ? toId : entry.entityId),
        payload: Value(jsonEncode(payload)),
      ));
    }
  }

  static Map<String, dynamic> _replace(
          Map<String, dynamic> map, String from, String to) =>
      map.map((key, value) => MapEntry(key, _replaceValue(value, from, to)));

  static Object? _replaceValue(Object? value, String from, String to) =>
      switch (value) {
        String() when value == from => to,
        Map() => _replace(Map<String, dynamic>.from(value), from, to),
        List() => [for (final v in value) _replaceValue(v, from, to)],
        _ => value,
      };

  /// Cuántas esperan envío y cuántas esperan al usuario.
  static Future<({int pending, int attention})> counts(AppDatabase db) async {
    final rows = await db.select(db.outbox).get();
    var pending = 0;
    var attention = 0;
    for (final row in rows) {
      if (row.status == OutboxStatus.pending.name) {
        pending++;
      } else {
        attention++;
      }
    }
    return (pending: pending, attention: attention);
  }
}
