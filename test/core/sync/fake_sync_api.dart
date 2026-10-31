import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:login_signup/core/database/local_database_holder.dart';
import 'package:login_signup/core/sync/sync_api.dart';
import 'package:login_signup/core/sync/sync_models.dart';

/// Base local en memoria para tests (una por holder).
LocalDatabaseHolder memoryDatabases({String? Function()? userId}) {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  return LocalDatabaseHolder(
    currentUserId: () async => userId == null ? 'user-1' : userId(),
    open: (_) => NativeDatabase.memory(),
  );
}

DioException offlineError() => DioException(
    requestOptions: RequestOptions(path: '/sync'),
    type: DioExceptionType.connectionError);

/// Servidor de sincronización simulado (contrato de `/sync`, 10.01): guarda
/// clientes, fusiona por teléfono, es idempotente por `mutation_id` y da
/// versiones crecientes al feed. Se le pueden forzar resultados y cortes.
class FakeSyncServer implements SyncApi {
  final clients = <String, Map<String, dynamic>>{};

  /// Registros de las demás entidades del feed (10.02b).
  final docs = <String, Map<String, Map<String, dynamic>>>{};
  final _feed = <({int version, String entity, String id, String op})>[];
  final _results = <String, MutationResult>{};
  int _version = 0;

  /// Sin red: toda llamada lanza un error de conexión.
  bool offline = false;

  /// Corta la conexión después de aplicar N mutaciones del próximo lote (el
  /// servidor las guardó pero la app no recibe respuesta).
  int? cutAfter;

  /// Resultado forzado para una mutación (por tipo), en lugar de aplicarla.
  final forced = <String, MutationResult Function(String mutationId)>{};

  final pushedBatches = <List<PushMutation>>[];
  int pullCalls = 0;

  int get version => _version;

  /// Cambio hecho por "otro dispositivo".
  void serverUpsertClient(String id, Map<String, dynamic> data) {
    clients[id] = {...?clients[id], ...data, 'id': id};
    _bump('clients', id, 'upsert');
  }

  /// Cambio de otra entidad hecho en el servidor.
  void serverUpsert(String entity, String id, Map<String, dynamic> data) {
    (docs[entity] ??= {})[id] = {...?docs[entity]?[id], ...data, 'id': id};
    _bump(entity, id, 'upsert');
  }

  void serverDelete(String entity, String id) {
    docs[entity]?.remove(id);
    _bump(entity, id, 'delete');
  }

  void serverLeaveScope(String entity, String id) =>
      _bump(entity, id, 'leave_scope');

  void serverDeleteClient(String id) {
    clients.remove(id);
    _bump('clients', id, 'delete');
  }

  void _bump(String entity, String id, String op) =>
      _feed.add((version: ++_version, entity: entity, id: id, op: op));

  @override
  Future<List<MutationResult>> push(
      String deviceId, List<PushMutation> mutations) async {
    if (offline) throw offlineError();
    pushedBatches.add(mutations);
    final results = <MutationResult>[];
    for (final (index, m) in mutations.indexed) {
      if (cutAfter != null && index >= cutAfter!) {
        cutAfter = null;
        throw offlineError();
      }
      results.add(_results[m.mutationId] ??= _apply(m));
    }
    return results;
  }

  MutationResult _apply(PushMutation m) {
    final forcedResult = forced[m.type];
    if (forcedResult != null) return forcedResult(m.mutationId);
    final id = m.entityId!;
    switch (m.type) {
      case 'client.create':
      case 'client.import':
        final existing = clients.entries
            .where((e) => e.value['phone'] == m.payload['phone'])
            .map((e) => e.key)
            .firstOrNull;
        if (existing != null) {
          return MutationResult(
              mutationId: m.mutationId,
              status: MutationStatus.merged,
              mergedInto: existing);
        }
        serverUpsertClient(id, {
          ...m.payload,
          'isActive': true,
          'isFromDevice': m.type == 'client.import',
          'created_at': '2026-10-31T13:00:00.000Z',
        });
      case 'client.update':
        if (!clients.containsKey(id)) {
          return MutationResult(
              mutationId: m.mutationId,
              status: MutationStatus.conflict,
              code: 'NOT_FOUND',
              message: 'Cliente no encontrado');
        }
        serverUpsertClient(id, m.payload);
      case 'client.delete':
        if (clients.containsKey(id)) serverDeleteClient(id);
    }
    return MutationResult(
        mutationId: m.mutationId, status: MutationStatus.applied);
  }

  @override
  Future<ChangesPage> changes(String cursor, {int limit = 500}) async {
    if (offline) throw offlineError();
    pullCalls++;
    final from = int.parse(cursor);
    final pending = _feed.where((c) => c.version > from).toList();
    final page = pending.take(limit).toList();
    return ChangesPage(
      changes: [
        for (final c in page)
          SyncChange(
            entity: c.entity,
            id: c.id,
            op: ChangeOp.fromApi(c.op)!,
            data: c.op != 'upsert'
                ? null
                : c.entity == 'clients'
                    ? clients[c.id]
                    : docs[c.entity]?[c.id],
          ),
      ],
      cursor: page.isEmpty ? cursor : '${page.last.version}',
      hasMore: pending.length > page.length,
    );
  }
}
