import 'package:drift/drift.dart';
import 'package:login_signup/core/database/tables/client_tables.dart';
import 'package:login_signup/core/database/tables/document_tables.dart';
import 'package:login_signup/core/database/tables/sync_tables.dart';

export 'package:login_signup/core/database/tables/client_tables.dart';
export 'package:login_signup/core/database/tables/document_tables.dart';
export 'package:login_signup/core/database/tables/sync_tables.dart';

part 'app_database.g.dart';

/// Base local de la app (10.02, D-18): drift sobre SQLite. Una por usuario
/// (`LocalDatabaseHolder`). Las features leen siempre de aquí; lo que se
/// escribe va también a [Outbox] y lo sube `SyncEngine`.
///
/// Esquema en `core/database/tables/` (lo comparten el motor y las
/// features). Al cambiarlo: subir [schemaVersion], añadir el paso en
/// [migration] y regenerar con `dart run build_runner build`.
@DriftDatabase(
    tables: [Outbox, SyncMeta, IdRemaps, LocalClients, LocalDocuments])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          // 1 → 2 (10.02b): registros del resto de entidades.
          if (from < 2) {
            await m.createTable(localDocuments);
            await m.createIndex(idxDocumentsRef1);
            await m.createIndex(idxDocumentsRef2);
            await m.createIndex(idxDocumentsAt);
          }
          // 2 → 3 (11.04): consentimiento de WhatsApp de los clientes.
          if (from < 3) {
            await m.addColumn(localClients, localClients.whatsappOptIn);
            await m.addColumn(localClients, localClients.whatsappOptInAt);
            await m.addColumn(localClients, localClients.whatsappOptOutAt);
          }
          // 3 → 4 (11.06): origen del consentimiento. Bajada completa para
          // rellenarlo en los clientes que ya estaban.
          if (from < 4) {
            await m.addColumn(localClients, localClients.whatsappOptInSource);
            await (update(syncMeta)..where((t) => t.key.equals('cursor')))
                .write(const SyncMetaCompanion(value: Value('0')));
          }
        },
      );
}
