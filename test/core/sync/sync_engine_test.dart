import 'package:flutter_test/flutter_test.dart';
import 'package:login_signup/core/database/app_database.dart';
import 'package:login_signup/core/database/local_database_holder.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/sync/offline_store.dart';
import 'package:login_signup/core/sync/outbox_store.dart';
import 'package:login_signup/core/sync/sync_engine.dart';
import 'package:login_signup/core/sync/sync_models.dart';
import 'package:login_signup/features/clients/data/datasources/clients_local_datasource.dart';
import 'package:login_signup/features/clients/data/sync/clients_sync_handler.dart';
import 'package:login_signup/features/clients/domain/entities/clients_query.dart';

import 'fake_sync_api.dart';

/// Motor de sincronización con red simulada (10.02, D-18).
void main() {
  late LocalDatabaseHolder databases;
  late FakeSyncServer server;
  late SyncEngine engine;
  late OfflineStore store;
  late AppDatabase db;
  const local = ClientsLocalDataSource();
  var ids = 0;

  setUp(() async {
    databases = memoryDatabases();
    server = FakeSyncServer();
    engine = SyncEngine(
      databases: databases,
      api: server,
      handlers: [ClientsSyncHandler(local)],
      pushBatchSize: 3,
      pullPageSize: 2,
    );
    ids = 0;
    store = OfflineStore(
      databases: databases,
      clock: () => DateTime.utc(2026, 10, 31, 12),
      newId: () => 'id-${++ids}',
    );
    db = await databases.require();
  });

  tearDown(() async {
    await engine.dispose();
    await databases.close();
  });

  /// Alta local + `client.create` en la bandeja (como el repositorio).
  Future<void> createLocal(String id, String phone, {String name = 'Ana'}) =>
      store.write((db, sink) async {
        final payload = {'name': name, 'lastname': '', 'phone': phone};
        await local.upsertFields(db, id, payload);
        await sink.add(
            type: 'client.create',
            entity: 'clients',
            entityId: id,
            payload: payload);
      });

  Future<void> updateLocal(String id, Map<String, dynamic> changes) =>
      store.write((db, sink) async {
        await local.upsertFields(db, id, changes);
        await sink.add(
            type: 'client.update',
            entity: 'clients',
            entityId: id,
            payload: changes);
      });

  Future<List<String>> localNames() async =>
      (await local.page(db, const ClientsQuery(sortBy: ClientSortField.name,
              direction: SortDirection.asc)))
          .items
          .map((c) => c.name)
          .toList();

  test('carga inicial paginada hasta has_more = false', () async {
    for (var i = 0; i < 5; i++) {
      server.serverUpsertClient('s$i', {'name': 'C$i', 'phone': '30000000$i'});
    }
    await engine.syncNow();
    expect(await localNames(), ['C0', 'C1', 'C2', 'C3', 'C4']);
    expect(server.pullCalls, 3, reason: 'páginas de 2');
    expect(await SyncEngine.cursorOf(db), '5');
    expect(engine.current.online, true);
    expect(engine.current.lastSyncedAt, isNotNull);
  });

  test('sin conexión: se escribe en local, nada sale de la bandeja', () async {
    server.offline = true;
    await createLocal('a', '3001112222');
    await engine.syncNow();
    expect(await localNames(), ['Ana']);
    expect((await OutboxStore.all(db)).length, 1);
    expect(engine.current.online, false);
    expect(engine.current.pending, 1);
    expect(server.clients, isEmpty);
  });

  test('reconexión: sube la bandeja en orden y luego baja', () async {
    server.offline = true;
    await createLocal('a', '3001112222');
    await updateLocal('a', {'name': 'Ana María'});
    await engine.syncNow();

    server.offline = false;
    server.serverUpsertClient('b', {'name': 'Beto', 'phone': '3009998888'});
    await engine.syncNow();

    expect(server.clients['a']!['name'], 'Ana María');
    expect(server.pushedBatches.single.map((m) => m.type),
        ['client.create', 'client.update']);
    expect(await OutboxStore.all(db), isEmpty);
    expect(await localNames(), ['Ana María', 'Beto']);
    expect(engine.current.online, true);
    expect(engine.current.pending, 0);
  });

  test('lotes de como mucho pushBatchSize, en orden', () async {
    for (var i = 0; i < 7; i++) {
      await createLocal('c$i', '310000000$i', name: 'N$i');
    }
    await engine.syncNow();
    expect(server.pushedBatches.map((b) => b.length), [3, 3, 1]);
    expect(await OutboxStore.all(db), isEmpty);
    expect(server.clients.length, 7);
  });

  test('merged: el id local pasa al del servidor (fila, bandeja y alias)',
      () async {
    server.serverUpsertClient('srv', {'name': 'Ana', 'phone': '3001112222'});
    server.offline = true;
    await createLocal('local', '3001112222');
    await updateLocal('local', {'notes': 'VIP'});
    server.offline = false;
    // El update va después del create en el mismo lote: el servidor (como el
    // real, con alias) lo aplica sobre el fusionado.
    server.forced['client.update'] = (mid) =>
        MutationResult(mutationId: mid, status: MutationStatus.applied);
    await engine.syncNow();

    final remap = await db.select(db.idRemaps).getSingle();
    expect((remap.fromId, remap.toId), ('local', 'srv'));
    expect(await local.byId(db, 'local'), isNotNull,
        reason: 'el id viejo se resuelve por el alias');
    expect((await local.byId(db, 'local'))!.id, 'srv');
    expect((await local.page(db, const ClientsQuery())).total, 1);
    expect(await OutboxStore.all(db), isEmpty);
  });

  test('merged reasigna referencias de mutaciones aún pendientes', () async {
    await createLocal('local', '3001112222');
    await OutboxStore.enqueue(db,
        mutationId: 'm-otra',
        type: 'client.update',
        entity: 'clients',
        entityId: 'local',
        payload: {'client_id': 'local'},
        clientTime: DateTime.utc(2026));
    await OutboxStore.remapIds(db, 'local', 'srv');
    final entry = (await OutboxStore.all(db))
        .firstWhere((e) => e.mutationId == 'm-otra');
    expect(entry.entityId, 'srv');
    expect(entry.payload['client_id'], 'srv');
  });

  test('conflict sin guardar: queda en la bandeja y lo local vuelve al '
      'servidor', () async {
    server.serverUpsertClient('a', {'name': 'Ana', 'phone': '3001112222'});
    await engine.syncNow();
    server.serverDeleteClient('a'); // otro dispositivo lo borró
    await updateLocal('a', {'name': 'Editada'});
    await engine.syncNow();

    final entry = (await OutboxStore.all(db)).single;
    expect(entry.status, OutboxStatus.conflict);
    expect(entry.code, 'NOT_FOUND');
    expect(await local.byId(db, 'a'), isNull, reason: 'el borrado gana');
    expect(engine.current.needsAttention, 1);
    expect(engine.current.pending, 0);

    // No se reenvía sola.
    final pushes = server.pushedBatches.length;
    await engine.syncNow();
    expect(server.pushedBatches.length, pushes);
  });

  test('conflict guardado (saved): sale de la bandeja; llega con la bajada',
      () async {
    server.forced['client.create'] = (mid) => MutationResult(
        mutationId: mid,
        status: MutationStatus.conflict,
        code: 'SLOT_UNAVAILABLE',
        saved: true);
    await createLocal('a', '3001112222');
    await engine.syncNow();
    expect(await OutboxStore.all(db), isEmpty);
  });

  test('rejected: se queda en la bandeja con su motivo; retry la reenvía',
      () async {
    server.forced['client.create'] = (mid) => MutationResult(
        mutationId: mid,
        status: MutationStatus.rejected,
        code: 'VALIDATION_ERROR',
        message: 'El teléfono no es válido');
    await createLocal('a', '3001112222');
    await engine.syncNow();

    var entry = (await OutboxStore.all(db)).single;
    expect(entry.status, OutboxStatus.rejected);
    expect(entry.message, 'El teléfono no es válido');
    expect(engine.current.needsAttention, 1);

    // No se reenvía sola…
    await engine.syncNow();
    expect(server.pushedBatches.length, 1);

    // …hasta que el usuario la reintenta (el servidor ya la aceptaría).
    server.forced.clear();
    await OutboxStore.retry(db, entry.mutationId);
    await engine.syncNow();
    expect(server.pushedBatches.length, 2);
    // Mismo mutation_id: el servidor devuelve el resultado guardado.
    entry = (await OutboxStore.all(db)).single;
    expect(entry.status, OutboxStatus.rejected);
  });

  test('rechazo transitorio (TRIAL_LIMIT_REACHED): se reintenta en cada '
      'pasada y no se deshace lo local', () async {
    var calls = 0;
    server.forced['client.create'] = (mid) {
      calls++;
      return MutationResult(
          mutationId: mid,
          status: MutationStatus.rejected,
          code: 'TRIAL_LIMIT_REACHED');
    };
    await createLocal('a', '3001112222');
    await engine.syncNow();
    expect(await local.byId(db, 'a'), isNotNull);
    expect((await OutboxStore.all(db)).single.isTransientRejection, true);
    await engine.syncNow();
    expect(server.pushedBatches.length, 2, reason: 'se reenvía sola');
    expect(calls, 1, reason: 'el fake devuelve el resultado guardado');
  });

  test('retry del servidor: se queda pendiente y se reenvía', () async {
    server.forced['client.create'] = (mid) =>
        MutationResult(mutationId: mid, status: MutationStatus.retry);
    await createLocal('a', '3001112222');
    await engine.syncNow();
    final entry = (await OutboxStore.all(db)).single;
    expect(entry.status, OutboxStatus.pending);
    expect(entry.attempts, 1);
  });

  test('idempotencia: repetir un lote no duplica', () async {
    await createLocal('a', '3001112222');
    final batch = [
      for (final e in await OutboxStore.all(db)) e.toPush(),
    ];
    final first = await server.push('dev', batch);
    final second = await server.push('dev', batch);
    expect(second.single.status, first.single.status);
    expect(server.clients.length, 1);
    expect(server.version, 1);
  });

  test('corte a mitad de un lote: nada sale de la bandeja; al reenviar, el '
      'servidor responde lo ya aplicado sin duplicar', () async {
    for (var i = 0; i < 3; i++) {
      await createLocal('c$i', '310000000$i', name: 'N$i');
    }
    server.cutAfter = 2; // aplica 2 y se cae la conexión
    await engine.syncNow();
    expect(server.clients.length, 2, reason: 'el servidor sí las guardó');
    expect((await OutboxStore.all(db)).length, 3,
        reason: 'sin respuesta no se borra nada');
    expect(engine.current.online, false);

    await engine.syncNow();
    expect(await OutboxStore.all(db), isEmpty);
    expect(server.clients.length, 3);
    expect(server.version, 3, reason: 'sin escrituras repetidas');
    expect((await local.page(db, const ClientsQuery())).total, 3);
  });

  test('bajada que pisa una fila con cambios pendientes los reaplica',
      () async {
    server.serverUpsertClient('a', {'name': 'Ana', 'phone': '3001112222'});
    await engine.syncNow();
    server.offline = true;
    await updateLocal('a', {'notes': 'local'});
    await engine.syncNow();
    server.offline = false;
    server.serverUpsertClient('a', {'lastname': 'Servidor'});
    server.offline = false;
    // Solo la bajada (la bandeja aún no se ha subido): simula que la subida
    // falló por un error temporal.
    server.forced['client.update'] = (mid) =>
        MutationResult(mutationId: mid, status: MutationStatus.retry);
    await engine.syncNow();
    final client = (await local.byId(db, 'a'))!;
    expect(client.lastname, 'Servidor');
    expect(client.notes, 'local');
  });

  test('borrado y leave_scope de la bajada quitan la fila local', () async {
    server.serverUpsertClient('a', {'name': 'Ana', 'phone': '3001112222'});
    await engine.syncNow();
    server.serverDeleteClient('a');
    await engine.syncNow();
    expect(await local.byId(db, 'a'), isNull);
  });

  test('una entidad nueva en la app reinicia el cursor (bajada completa)',
      () async {
    server.serverUpsertClient('a', {'name': 'Ana', 'phone': '3001112222'});
    final bare = SyncEngine(databases: databases, api: server);
    await bare.syncNow();
    expect(await SyncEngine.cursorOf(db), '1');
    expect(await local.byId(db, 'a'), isNull, reason: 'sin handler');

    await engine.syncNow(); // con el handler de clientes
    expect(await local.byId(db, 'a'), isNotNull);
    await bare.dispose();
  });

  test('una sola pasada a la vez; lo pedido durante una se hace después',
      () async {
    server.serverUpsertClient('a', {'name': 'Ana', 'phone': '3001112222'});
    final first = engine.syncNow();
    final second = engine.syncNow();
    expect(identical(first, second), true);
    await first;
    expect(server.pullCalls, 2, reason: 'la segunda corrió al terminar');
  });

  test('requestSync agrupa escrituras (debounce)', () async {
    final quick = SyncEngine(
        databases: databases,
        api: server,
        handlers: [ClientsSyncHandler(local)],
        debounce: const Duration(milliseconds: 30));
    await createLocal('a', '3001112222');
    quick.requestSync();
    quick.requestSync();
    quick.requestSync();
    await Future<void>.delayed(const Duration(milliseconds: 120));
    expect(server.pushedBatches.length, 1);
    await quick.dispose();
  });

  test('sin sesión no hace nada', () async {
    final none = SyncEngine(
        databases: memoryDatabases(userId: () => null), api: server);
    await none.syncNow();
    expect(server.pullCalls, 0);
    await none.dispose();
  });

  test('error que no es de red queda en lastError', () async {
    final failing = SyncEngine(databases: databases, api: _Unauthorized());
    await failing.syncNow();
    expect(failing.current.lastError, isA<Failure>());
    expect(failing.current.online, true);
    await failing.dispose();
  });
}

class _Unauthorized extends FakeSyncServer {
  @override
  Future<ChangesPage> changes(String cursor, {int limit = 500}) =>
      throw StateError('respuesta rara');
}
