import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:login_signup/core/database/app_database.dart';

/// Abre la base de un usuario (por defecto, un archivo SQLite por usuario en
/// la carpeta de documentos de la app).
typedef DatabaseOpener = QueryExecutor Function(String userId);

/// Dueño de la base local abierta (10.02): **una por usuario**, para que
/// cerrar sesión no borre lo pendiente de subir (D-18: nada se pierde sin
/// respuesta del servidor) y otro usuario del mismo teléfono no vea esos
/// datos. Se abre al primer uso con la sesión vigente y se cambia sola si
/// cambia el usuario.
class LocalDatabaseHolder {
  final Future<String?> Function() _currentUserId;
  final DatabaseOpener _open;

  String? _userId;
  AppDatabase? _database;

  LocalDatabaseHolder({
    required Future<String?> Function() currentUserId,
    DatabaseOpener? open,
  })  : _currentUserId = currentUserId,
        _open = open ?? _defaultOpener;

  static QueryExecutor _defaultOpener(String userId) =>
      driftDatabase(name: 'agendity_$userId');

  /// Base del usuario de la sesión, o `null` sin sesión.
  Future<AppDatabase?> current() async {
    final userId = await _currentUserId();
    if (userId == null) return null;
    if (_database != null && _userId == userId) return _database;
    await close();
    _userId = userId;
    return _database = AppDatabase(_open(userId));
  }

  /// Como [current], pero sin sesión lanza `StateError` (los repositorios
  /// solo se usan con sesión; `safeCall` lo convierte en failure).
  Future<AppDatabase> require() async {
    final database = await current();
    if (database == null) {
      throw StateError('Sin sesión: no hay base local');
    }
    return database;
  }

  Future<void> close() async {
    final database = _database;
    _database = null;
    _userId = null;
    await database?.close();
  }
}
