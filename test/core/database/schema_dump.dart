// Genera el esquema guardado de la versión actual de la base local:
//
//   SCHEMA_DUMP=1 flutter test test/core/database/schema_dump.dart
//
// Escribe `test/core/database/schemas/schema_v<schemaVersion>.sql` (sin
// SCHEMA_DUMP no hace nada). Se corre al subir `schemaVersion` (regla de
// ARQUITECTURA §4) y el archivo se sube con el cambio; `migration_test.dart`
// falla si falta o si no coincide con lo que crea la app.
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:login_signup/core/database/app_database.dart';

void main() {
  test('volcar el esquema actual', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final rows = await db
        .customSelect("SELECT sql FROM sqlite_master WHERE sql IS NOT NULL "
            "AND name NOT LIKE 'sqlite_%' ORDER BY type DESC, name")
        .get();
    final sql = [for (final r in rows) '${r.read<String>('sql')};'].join('\n');
    File('test/core/database/schemas/schema_v${db.schemaVersion}.sql')
        .writeAsStringSync('$sql\n');
    await db.close();
  }, skip: Platform.environment['SCHEMA_DUMP'] == null
      ? 'Solo con SCHEMA_DUMP=1'
      : null);
}
