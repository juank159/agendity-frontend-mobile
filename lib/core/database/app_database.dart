import 'package:drift/drift.dart';
import 'package:login_signup/core/database/tables/client_tables.dart';
import 'package:login_signup/core/database/tables/sync_tables.dart';

export 'package:login_signup/core/database/tables/client_tables.dart';
export 'package:login_signup/core/database/tables/sync_tables.dart';

part 'app_database.g.dart';

/// Base local de la app (10.02, D-18): drift sobre SQLite. Una por usuario
/// (`LocalDatabaseHolder`). Las features leen siempre de aquí; lo que se
/// escribe va también a [Outbox] y lo sube `SyncEngine`.
///
/// Esquema en `core/database/tables/` (lo comparten el motor y las
/// features). Al cambiarlo: subir [schemaVersion], añadir el paso en
/// [migration] y regenerar con `dart run build_runner build`.
@DriftDatabase(tables: [Outbox, SyncMeta, IdRemaps, LocalClients])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
      );
}
