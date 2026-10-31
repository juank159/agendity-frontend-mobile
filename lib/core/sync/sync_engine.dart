import 'dart:async';

import 'package:login_signup/core/database/app_database.dart';
import 'package:login_signup/core/database/local_database_holder.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/network/error_mapper.dart';
import 'package:login_signup/core/sync/outbox_store.dart';
import 'package:login_signup/core/sync/sync_api.dart';
import 'package:login_signup/core/sync/sync_entity_handler.dart';
import 'package:login_signup/core/sync/sync_models.dart';
import 'package:login_signup/core/utils/app_logger.dart';
import 'package:uuid/uuid.dart';

/// Estado visible de la sincronización (10.03 FP lo pinta).
class SyncStatus {
  /// `false` si la última llamada al servidor falló por red.
  final bool online;
  final bool syncing;

  /// Operaciones esperando envío.
  final int pending;

  /// Rechazadas o en conflicto: esperan al usuario.
  final int needsAttention;
  final DateTime? lastSyncedAt;

  /// Último error que no fue de red (sesión, servidor…).
  final Failure? lastError;

  const SyncStatus({
    this.online = true,
    this.syncing = false,
    this.pending = 0,
    this.needsAttention = 0,
    this.lastSyncedAt,
    this.lastError,
  });

  SyncStatus copyWith({
    bool? online,
    bool? syncing,
    int? pending,
    int? needsAttention,
    DateTime? lastSyncedAt,
    Failure? lastError,
    bool clearError = false,
  }) =>
      SyncStatus(
        online: online ?? this.online,
        syncing: syncing ?? this.syncing,
        pending: pending ?? this.pending,
        needsAttention: needsAttention ?? this.needsAttention,
        lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
        lastError: clearError ? null : lastError ?? this.lastError,
      );
}

/// Motor de sincronización (10.02, D-18): **sube** la bandeja en lotes y
/// luego **baja** los cambios con el cursor hasta `has_more = false`.
///
/// - Corre con [syncNow]; [requestSync] lo agenda con debounce (después de
///   cada escritura), [start] lo repite cada [interval] (más seguido sin
///   red: así detecta la vuelta de internet) y la DI lo llama al iniciar
///   sesión y al volver la app a primer plano.
/// - Una sola ejecución a la vez; lo que se pide mientras corre se hace al
///   terminar.
/// - Nada sale de la bandeja sin un resultado del servidor: sin respuesta
///   (red caída a mitad de un lote), el lote entero se reenvía y el
///   servidor devuelve lo mismo (idempotente por `mutation_id`).
class SyncEngine {
  final LocalDatabaseHolder _databases;
  final SyncApi _api;
  final Map<String, SyncEntityHandler> _handlers = {};
  final Duration debounce;
  final Duration interval;
  final Duration offlineInterval;
  final int pushBatchSize;
  final int pullPageSize;

  final _status = StreamController<SyncStatus>.broadcast();
  SyncStatus _current = const SyncStatus();

  Future<void>? _running;
  bool _again = false;
  Timer? _debounceTimer;
  Timer? _periodic;

  static const cursorKey = 'cursor';
  static const deviceKey = 'device_id';
  static const entitiesKey = 'entities';
  static const epochKey = 'server_epoch';

  SyncEngine({
    required LocalDatabaseHolder databases,
    required SyncApi api,
    Iterable<SyncEntityHandler> handlers = const [],
    this.debounce = const Duration(seconds: 2),
    this.interval = const Duration(minutes: 2),
    this.offlineInterval = const Duration(seconds: 20),
    this.pushBatchSize = 100,
    this.pullPageSize = 500,
  })  : _databases = databases,
        _api = api {
    handlers.forEach(register);
  }

  /// Lo llama cada feature (`<f>_dependencies.dart`).
  void register(SyncEntityHandler handler) =>
      _handlers[handler.entity] = handler;

  Stream<SyncStatus> get status => _status.stream;
  SyncStatus get current => _current;

  // ------------------------------------------------------------- Disparadores

  /// Sincroniza cada [interval] (o [offlineInterval] sin red).
  void start() {
    _periodic?.cancel();
    _periodic = Timer(_current.online ? interval : offlineInterval, () {
      unawaited(syncNow().whenComplete(start));
    });
  }

  void stop() {
    _periodic?.cancel();
    _debounceTimer?.cancel();
    _periodic = null;
    _debounceTimer = null;
  }

  /// Sincroniza dentro de [debounce] (o ya, con [immediate]).
  void requestSync({bool immediate = false}) {
    _debounceTimer?.cancel();
    if (immediate) {
      unawaited(syncNow());
      return;
    }
    unawaited(refreshCounts());
    _debounceTimer = Timer(debounce, () => unawaited(syncNow()));
  }

  /// Una pasada (subida + bajada). Si ya hay una en curso, se repite al
  /// terminar y se devuelve esa.
  Future<void> syncNow() {
    final running = _running;
    if (running != null) {
      _again = true;
      return running;
    }
    return _running = _loop().whenComplete(() => _running = null);
  }

  Future<void> _loop() async {
    do {
      _again = false;
      await _run();
    } while (_again);
  }

  Future<void> _run() async {
    final db = await _databases.current();
    if (db == null) return; // sin sesión
    _emit(_current.copyWith(syncing: true));
    try {
      await _prepare(db);
      await _push(db);
      await _pull(db);
      _emit(_current.copyWith(
          online: true, lastSyncedAt: DateTime.now(), clearError: true));
    } catch (error) {
      final failure = ErrorMapper.fromObject(error);
      if (failure is NetworkFailure) {
        _emit(_current.copyWith(online: false));
      } else {
        AppLogger.error('Sincronización', failure.message);
        _emit(_current.copyWith(online: true, lastError: failure));
      }
    } finally {
      await _refreshCounts(db);
      _emit(_current.copyWith(syncing: false));
    }
  }

  // ------------------------------------------------------------------ Subida

  Future<void> _push(AppDatabase db) async {
    final deviceId = await _meta(db, deviceKey) ?? '';
    var afterSeq = 0;
    while (true) {
      final batch = await OutboxStore.sendable(db,
          afterSeq: afterSeq, limit: pushBatchSize);
      if (batch.isEmpty) return;
      // Sin respuesta, lanza: nada del lote se toca.
      final results = await _api.push(
          deviceId, [for (final entry in batch) entry.toPush()]);
      final byId = {for (final r in results) r.mutationId: r};

      final toRestore = <OutboxEntry>[];
      var stop = false;
      await db.transaction(() async {
        for (final entry in batch) {
          final result = byId[entry.mutationId];
          if (result == null || result.status == MutationStatus.retry) {
            // Sin resultado o error temporal: se queda pendiente.
            await OutboxStore.countAttempt(db, entry.mutationId);
            stop = true;
            continue;
          }
          if (await _applyResult(db, entry, result)) toRestore.add(entry);
        }
      });
      for (final entry in toRestore) {
        await _restore(db, entry);
      }
      if (stop) return; // reintentar en la próxima pasada
      afterSeq = batch.last.seq;
    }
  }

  /// Aplica el resultado de una mutación. `true` si hay que devolver el
  /// registro a la versión del servidor.
  Future<bool> _applyResult(
      AppDatabase db, OutboxEntry entry, MutationResult result) async {
    switch (result.status) {
      case MutationStatus.applied:
        await OutboxStore.remove(db, entry.mutationId);
        return false;
      case MutationStatus.merged:
        final into = result.mergedInto;
        if (into != null && entry.entityId != null && into != entry.entityId) {
          await _remap(db, entry.entity, entry.entityId!, into);
        }
        await OutboxStore.remove(db, entry.mutationId);
        return false;
      case MutationStatus.conflict:
        if (result.saved) {
          // Guardada en el servidor para revisarla: llega con la bajada.
          await OutboxStore.remove(db, entry.mutationId);
          return false;
        }
        await OutboxStore.mark(db, entry.mutationId, OutboxStatus.conflict,
            code: result.code, message: result.message);
        return true;
      case MutationStatus.rejected:
        await OutboxStore.mark(db, entry.mutationId, OutboxStatus.rejected,
            code: result.code, message: result.message);
        return !OutboxEntry.transientCodes.contains(result.code);
      case MutationStatus.retry:
        return false;
    }
  }

  Future<void> _remap(
      AppDatabase db, String entity, String fromId, String toId) async {
    await db.into(db.idRemaps).insertOnConflictUpdate(IdRemapsCompanion.insert(
        entity: entity, fromId: fromId, toId: toId));
    await OutboxStore.remapIds(db, fromId, toId);
    for (final handler in _handlers.values) {
      await handler.remap(db, entity, fromId, toId);
    }
  }

  Future<void> _restore(AppDatabase db, OutboxEntry entry) async {
    final handler = _handlers[entry.entity];
    final id = entry.entityId;
    if (handler == null || id == null) return;
    try {
      await handler.restore(db, id);
    } catch (error) {
      AppLogger.debug('No se pudo restaurar ${entry.entity}: '
          '${error.runtimeType}');
    }
  }

  // ------------------------------------------------------------------ Bajada

  Future<void> _pull(AppDatabase db) async {
    var cursor = await _meta(db, cursorKey) ?? '0';
    var rebuilding = false;
    while (true) {
      final page = await _api.changes(cursor, limit: pullPageSize);
      if (!rebuilding && await _isStale(db, cursor, page)) {
        // La base local es de otro servidor o de antes de una restauración:
        // se baja todo de nuevo (la bandeja no se toca).
        await _resetLocalData(db, page.epoch);
        cursor = '0';
        rebuilding = true;
        continue;
      }
      if (page.epoch != null && await _meta(db, epochKey) == null) {
        await _setMeta(db, epochKey, page.epoch!);
      }
      await db.transaction(() async {
        for (final change in page.changes) {
          await _applyChange(db, change, replayPending: !rebuilding);
        }
        await _setMeta(db, cursorKey, page.cursor);
      });
      cursor = page.cursor;
      if (!page.hasMore) break;
    }
    if (rebuilding) await _replayAllPending(db);
  }

  /// ¿Lo local no corresponde a este servidor? Otra base ([ChangesPage.epoch]
  /// distinto del guardado) o un cursor por delante de su última versión
  /// ([ChangesPage.head]).
  Future<bool> _isStale(AppDatabase db, String cursor, ChangesPage page) async {
    final stored = await _meta(db, epochKey);
    if (page.epoch != null && stored != null && page.epoch != stored) {
      return true;
    }
    final head = BigInt.tryParse(page.head ?? '');
    final local = BigInt.tryParse(cursor);
    return head != null && local != null && local > head;
  }

  /// Borra los datos bajados (no la bandeja) y deja el cursor en 0.
  Future<void> _resetLocalData(AppDatabase db, String? epoch) async {
    AppLogger.debug('Base local de otro servidor: se baja todo de nuevo');
    await db.transaction(() async {
      await db.delete(db.localDocuments).go();
      await db.delete(db.localClients).go();
      await db.delete(db.idRemaps).go();
      await _setMeta(db, cursorKey, '0');
      if (epoch != null) await _setMeta(db, epochKey, epoch);
    });
  }

  /// Tras bajar todo de nuevo: lo local = servidor + lo pendiente de subir,
  /// en orden (lo rechazado sigue en la bandeja, como siempre, sin aplicar).
  Future<void> _replayAllPending(AppDatabase db) async {
    await db.transaction(() async {
      for (final entry in await OutboxStore.all(db)) {
        if (entry.status != OutboxStatus.pending &&
            !entry.isTransientRejection) {
          continue;
        }
        await _handlers[entry.entity]?.replay(db, entry);
      }
    });
  }

  Future<void> _applyChange(AppDatabase db, SyncChange change,
      {bool replayPending = true}) async {
    final handler = _handlers[change.entity];
    if (handler == null) return; // entidad que esta versión aún no guarda
    switch (change.op) {
      case ChangeOp.upsert:
        final data = change.data;
        if (data == null) return;
        await handler.upsert(db, change.id, data);
        if (!replayPending) return;
        // Lo local = servidor + lo que aún no se ha subido.
        for (final entry
            in await OutboxStore.pendingFor(db, change.entity, change.id)) {
          await handler.replay(db, entry);
        }
      case ChangeOp.delete:
        await handler.delete(db, change.id);
      case ChangeOp.leaveScope:
        await handler.leaveScope(db, change.id);
    }
  }

  // ------------------------------------------------------------------- Meta

  /// Id del dispositivo y, si cambió el conjunto de entidades que esta
  /// versión guarda (p. ej. al añadir una feature), bajada completa desde 0:
  /// lo que antes se ignoró ahora se guarda.
  Future<void> _prepare(AppDatabase db) async {
    if (await _meta(db, deviceKey) == null) {
      await _setMeta(db, deviceKey, const Uuid().v7());
    }
    final entities = (_handlers.keys.toList()..sort()).join(',');
    if (await _meta(db, entitiesKey) != entities) {
      await _setMeta(db, cursorKey, '0');
      await _setMeta(db, entitiesKey, entities);
    }
  }

  static Future<String?> _meta(AppDatabase db, String key) async =>
      (await (db.select(db.syncMeta)..where((m) => m.key.equals(key)))
              .getSingleOrNull())
          ?.value;

  static Future<void> _setMeta(AppDatabase db, String key, String value) =>
      db.into(db.syncMeta).insertOnConflictUpdate(
          SyncMetaCompanion.insert(key: key, value: value));

  /// Cursor guardado (tests y diagnóstico).
  static Future<String?> cursorOf(AppDatabase db) => _meta(db, cursorKey);

  // ------------------------------------------------- Decisiones del usuario

  /// Bandeja de la sesión, en orden (vacía sin sesión). La pantalla
  /// "Pendientes" (10.03) la muestra.
  Future<List<OutboxEntry>> entries() async {
    final db = await _databases.current();
    return db == null ? const [] : OutboxStore.all(db);
  }

  /// Vuelve a enviar una rechazada o en conflicto y sincroniza ya. Va como
  /// una mutación **nueva** (el servidor recuerda el rechazo de la anterior)
  /// y se vuelve a aplicar en local, porque el rechazo la había deshecho.
  ///
  /// Nunca puede duplicar algo que el servidor ya aplicó o guardó: solo se
  /// renueva una operación con un resultado del servidor que dice que **no**
  /// la aplicó (`rejected` o `conflict` sin guardar; los `applied`,
  /// `merged` y `conflict` guardados ya salieron de la bandeja). Una
  /// pendiente (sin respuesta: pudo aplicarse a mitad de un lote) o un
  /// rechazo transitorio (se reenvía solo, con su mismo `mutation_id`)
  /// conservan el id: solo se pide sincronizar.
  Future<void> retry(String mutationId) async {
    final db = await _databases.current();
    if (db == null) return;
    // Que no haya un envío en curso con esta operación.
    await _running;
    final entry = (await OutboxStore.all(db))
        .where((e) => e.mutationId == mutationId)
        .firstOrNull;
    if (entry == null) return;
    if (!canRenew(entry)) {
      requestSync(immediate: true);
      return;
    }
    final newId = const Uuid().v7();
    await OutboxStore.retryAsNew(db, mutationId,
        newMutationId: newId, clientTime: DateTime.now());
    final handler = _handlers[entry.entity];
    if (handler != null) {
      try {
        await handler.replay(db, (await OutboxStore.all(db))
            .firstWhere((e) => e.mutationId == newId));
      } catch (error) {
        AppLogger.debug('No se pudo reaplicar ${entry.entity}: '
            '${error.runtimeType}');
      }
    }
    await _refreshCounts(db);
    requestSync(immediate: true);
  }

  /// ¿Se puede reenviar [entry] con un `mutation_id` nuevo? Solo si el
  /// servidor respondió que no la aplicó y no la va a reevaluar sola.
  static bool canRenew(OutboxEntry entry) =>
      entry.status != OutboxStatus.pending && !entry.isTransientRejection;

  /// Renuncia a una operación rechazada o en conflicto (lo único que pierde
  /// datos, por decisión del usuario): sale de la bandeja y el registro
  /// local vuelve a la versión del servidor (un alta hecha sin conexión
  /// desaparece). Una **pendiente** no se puede descartar: aún no tiene
  /// respuesta del servidor y pudo aplicarse (D-18). Devuelve `false` si no
  /// se descartó.
  Future<bool> discard(String mutationId) async {
    final db = await _databases.current();
    if (db == null) return false;
    await _running;
    final entry = (await OutboxStore.all(db))
        .where((e) => e.mutationId == mutationId)
        .firstOrNull;
    if (entry == null || entry.status == OutboxStatus.pending) return false;
    await OutboxStore.discard(db, mutationId);
    // Otras pendientes del mismo registro siguen: solo se restaura si no
    // queda ninguna.
    final id = entry.entityId;
    if (id == null ||
        (await OutboxStore.all(db))
            .every((e) => e.entity != entry.entity || e.entityId != id)) {
      await _restore(db, entry);
    }
    await _refreshCounts(db);
    return true;
  }

  // ------------------------------------------------------------------ Estado

  Future<void> refreshCounts() async {
    final db = await _databases.current();
    if (db != null) {
      await _refreshCounts(db);
    } else {
      // Sin sesión no hay bandeja que mostrar (la del usuario sigue en su base).
      _emit(_current.copyWith(pending: 0, needsAttention: 0));
    }
  }

  Future<void> _refreshCounts(AppDatabase db) async {
    final counts = await OutboxStore.counts(db);
    _emit(_current.copyWith(
        pending: counts.pending, needsAttention: counts.attention));
  }

  void _emit(SyncStatus status) {
    _current = status;
    if (!_status.isClosed) _status.add(status);
  }

  /// Detiene los disparadores y espera la pasada en curso.
  Future<void> dispose() async {
    stop();
    await _running;
    await _status.close();
  }
}
