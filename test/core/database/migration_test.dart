import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:login_signup/core/database/app_database.dart';
import 'package:login_signup/core/database/local_database_holder.dart';
import 'package:login_signup/core/sync/outbox_store.dart';
import 'package:login_signup/core/sync/sync_engine.dart';
import 'package:login_signup/features/clients/data/datasources/clients_local_datasource.dart';
import 'package:login_signup/features/clients/data/sync/clients_sync_handler.dart';

import '../sync/fake_sync_api.dart';

/// Migraciones de la base local **sobre archivos reales** (D-18: la bandeja
/// no se puede perder nunca).
///
/// Regla (ARQUITECTURA §4): toda subida de `schemaVersion` guarda su esquema en
/// `test/core/database/schemas/schema_vN.sql` (lo genera
/// `test/core/database/schema_dump.dart`, ver su cabecera) y queda cubierta
/// aquí: cada esquema anterior guardado se crea en un archivo con datos y
/// mutaciones pendientes, se abre con la app actual y se comprueba que la
/// bandeja sigue intacta, que los datos quedan como se espera y que la
/// siguiente sincronización sube lo pendiente.
const schemasDir = 'test/core/database/schemas';

String schemaSql(int version) =>
    File('$schemasDir/schema_v$version.sql').readAsStringSync();

/// Sentencias del esquema guardado, las tablas antes que los índices.
List<String> schemaStatements(int version) {
  final statements = [
    for (final s in schemaSql(version).split(';\n'))
      if (s.trim().isNotEmpty) s.trim(),
  ];
  return [
    ...statements.where((s) => s.startsWith('CREATE TABLE')),
    ...statements.where((s) => !s.startsWith('CREATE TABLE')),
  ];
}

/// Abre un archivo con el esquema [version] tal cual (sin migraciones):
/// [create] corre el DDL guardado y los datos de prueba.
class _RawUser implements QueryExecutorUser {
  @override
  final int schemaVersion;
  final Future<void> Function(QueryExecutor executor) create;

  _RawUser(this.schemaVersion, this.create);

  @override
  Future<void> beforeOpen(
      QueryExecutor executor, OpeningDetails details) async {
    await executor.ensureOpen(this);
    await create(executor);
  }
}

Future<List<Map<String, Object?>>> rows(QueryExecutor e, String sql) =>
    e.runSelect(sql, const []);

/// Columnas de cada tabla (nombre, tipo, not null, default, pk) e índices:
/// la forma de una base, sin depender del texto del DDL (un `ADD COLUMN`
/// deja el SQL de la tabla escrito de otra manera).
Future<Map<String, Object>> shapeOf(QueryExecutor e) async {
  final tables = await rows(e,
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%' ORDER BY name");
  final shape = <String, Object>{};
  for (final t in tables) {
    final name = t['name'] as String;
    final columns = await rows(e, 'PRAGMA table_info("$name")');
    shape[name] = [
      for (final c in columns)
        '${c['name']}|${c['type']}|${c['notnull']}|${c['dflt_value']}|${c['pk']}',
    ]..sort();
  }
  final indexes = await rows(e,
      "SELECT name, tbl_name FROM sqlite_master WHERE type = 'index' AND name NOT LIKE 'sqlite_%' ORDER BY name");
  shape['#indexes'] = [for (final i in indexes) '${i['tbl_name']}.${i['name']}'];
  return shape;
}

/// Forma del esquema guardado [version].
Future<Map<String, Object>> savedShape(int version) async {
  final executor = NativeDatabase.memory();
  await executor.ensureOpen(_RawUser(version, (e) async {
    for (final statement in schemaStatements(version)) {
      await e.runCustom(statement);
    }
  }));
  final shape = await shapeOf(executor);
  await executor.close();
  return shape;
}

/// Mutaciones de prueba: dos pendientes y una rechazada, en ese orden.
const pending = [
  ('m-1', 'client.create', 'c-new', {'name': 'Nueva', 'phone': '3100000001'}),
  ('m-2', 'client.update', 'c-1', {'notes': 'VIP'}),
];
const rejected = ('m-3', 'client.delete', 'c-1', <String, Object>{});

Future<void> seed(QueryExecutor e, int version) async {
  for (final statement in schemaStatements(version)) {
    await e.runCustom(statement);
  }
  for (final (id, type, entity, payload) in [...pending, rejected]) {
    await e.runInsert(
        'INSERT INTO outbox (mutation_id, type, entity, entity_id, payload, '
        'client_time, status, code) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
        [
          id,
          type,
          'clients',
          entity,
          jsonEncode(payload),
          '2026-10-31T15:00:00.000Z',
          id == rejected.$1 ? 'rejected' : 'pending',
          id == rejected.$1 ? 'FORBIDDEN' : null,
        ]);
  }
  await e.runInsert(
      "INSERT INTO local_clients (id, name, phone, created_at) VALUES "
      "('c-1', 'Ana', '3000000001', '2026-10-01T15:00:00.000Z'), "
      "('c-new', 'Nueva', '3100000001', '2026-10-31T15:00:00.000Z')",
      const []);
  await e.runInsert(
      "INSERT INTO sync_meta (key, value) VALUES ('cursor', '57'), "
      "('device_id', 'dev-1'), ('entities', 'clients')",
      const []);
  await e.runInsert(
      "INSERT INTO id_remaps (entity, from_id, to_id) VALUES "
      "('clients', 'c-old', 'c-1')",
      const []);
  final hasDocuments = (await rows(e,
          "SELECT 1 FROM sqlite_master WHERE name = 'local_documents'"))
      .isNotEmpty;
  if (hasDocuments) {
    await e.runInsert(
        "INSERT INTO local_documents (entity, id, data, ref1, at) VALUES "
        "('appointments', 'apt-1', '{\"id\":\"apt-1\"}', 'pro-1', "
        "'2026-11-03T15:00:00.000Z')",
        const []);
  }
}

int get currentVersion => AppDatabase(NativeDatabase.memory()).schemaVersion;

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late Directory dir;

  setUp(() => dir = Directory.systemTemp.createTempSync('agendity_migration'));
  tearDown(() => dir.deleteSync(recursive: true));

  group('guardia de esquemas', () {
    test('cada versión hasta schemaVersion tiene su esquema guardado', () {
      for (var v = 1; v <= currentVersion; v++) {
        expect(File('$schemasDir/schema_v$v.sql').existsSync(), true,
            reason: 'Falta $schemasDir/schema_v$v.sql: al subir '
                'schemaVersion guarda el esquema nuevo (ver '
                'test/core/database/schema_dump.dart) y su test de migración '
                'con bandeja (ARQUITECTURA §4).');
      }
    });

    test('el esquema guardado de la versión actual es el que crea la app',
        () async {
      final db = AppDatabase(NativeDatabase.memory());
      await db.customSelect('SELECT 1').get();
      final fresh = await shapeOf(db.executor);
      await db.close();
      expect(fresh, await savedShape(currentVersion),
          reason: 'El esquema cambió sin subir schemaVersion o sin guardar '
              'schema_v$currentVersion.sql');
    });
  });

  for (var from = 1; from < currentVersion; from++) {
    test('$from → actual: bandeja intacta, datos y siguiente sincronización',
        () async {
      final file = File('${dir.path}/agendity_user.sqlite');
      final old = NativeDatabase(file);
      await old.ensureOpen(_RawUser(from, (e) => seed(e, from)));
      final outboxBefore = await rows(old, 'SELECT * FROM outbox ORDER BY seq');
      await old.close();

      // La app actual abre el mismo archivo: migra.
      final databases = LocalDatabaseHolder(
          currentUserId: () async => 'user-1',
          open: (_) => NativeDatabase(file));
      final db = await databases.require();
      await db.customSelect('SELECT 1').get(); // abre y migra
      final outboxAfter =
          await rows(db.executor, 'SELECT * FROM outbox ORDER BY seq');

      // 1. Bandeja intacta: mismas filas, mismo orden, mismos mutation_id.
      expect(outboxAfter, outboxBefore);
      expect((await OutboxStore.all(db)).map((e) => e.mutationId),
          ['m-1', 'm-2', 'm-3']);

      // 2. Forma = la del esquema actual guardado.
      expect(await shapeOf(db.executor), await savedShape(currentVersion));

      // 3. Datos: clientes, alias y registros se conservan; columnas nuevas
      // vacías; el cursor vuelve a 0 (bajada completa, 3 → 4) y el id del
      // dispositivo se conserva.
      const local = ClientsLocalDataSource();
      final ana = (await local.byId(db, 'c-1'))!;
      expect(ana.name, 'Ana');
      expect(ana.whatsappOptIn, isNull);
      expect((await local.byId(db, 'c-old'))!.id, 'c-1');
      if (from >= 2) {
        expect(
            await rows(db.executor,
                "SELECT id FROM local_documents WHERE entity = 'appointments'"),
            [
              {'id': 'apt-1'}
            ]);
      }
      expect(await SyncEngine.cursorOf(db), '0');
      expect(
          (await rows(db.executor,
                  "SELECT value FROM sync_meta WHERE key = 'device_id'"))
              .single['value'],
          'dev-1');

      // 4. La siguiente sincronización sube lo pendiente (no lo rechazado)
      // y baja todo de nuevo.
      final server = FakeSyncServer()
        ..serverUpsertClient('c-1', {'name': 'Ana', 'phone': '3000000001'});
      final engine = SyncEngine(
          databases: databases,
          api: server,
          handlers: [ClientsSyncHandler(local)]);
      await engine.syncNow();
      expect(
          server.pushedBatches.expand((b) => b).map((m) => m.mutationId),
          ['m-1', 'm-2']);
      expect(server.clients['c-new']!['name'], 'Nueva');
      expect(server.clients['c-1']!['notes'], 'VIP');
      final left = await OutboxStore.all(db);
      expect(left.map((e) => (e.mutationId, e.status)),
          [('m-3', OutboxStatus.rejected)]);
      expect((await local.byId(db, 'c-1'))!.notes, 'VIP');
      await engine.dispose();
      await databases.close();

      // 5. Reabrir no vuelve a migrar ni toca la bandeja.
      final again = AppDatabase(NativeDatabase(file));
      await again.customSelect('SELECT 1').get();
      expect((await OutboxStore.all(again)).single.mutationId, 'm-3');
      await again.close();
    });
  }
}
