import 'package:login_signup/core/database/app_database.dart';
import 'package:login_signup/core/database/local_database_holder.dart';
import 'package:login_signup/core/sync/outbox_store.dart';
import 'package:uuid/uuid.dart';

/// Lo que los repositorios usan para leer y escribir sin conexión (10.02):
/// la base del usuario, ids UUID v7 generados en la app y una escritura que
/// guarda el cambio local **y** su mutación en la bandeja en una sola
/// transacción. Después de cada escritura avisa al motor ([onWrite]) para
/// que sincronice (con debounce).
class OfflineStore {
  final LocalDatabaseHolder databases;
  final DateTime Function() _clock;
  final String Function() _newId;

  /// Lo conecta la DI con `SyncEngine.requestSync`.
  void Function()? onWrite;

  OfflineStore({
    required this.databases,
    DateTime Function()? clock,
    String Function()? newId,
    this.onWrite,
  })  : _clock = clock ?? DateTime.now,
        _newId = newId ?? _uuidV7;

  static const _uuid = Uuid();
  static String _uuidV7() => _uuid.v7();

  /// Id nuevo (UUID v7: ordenado por tiempo; el servidor lo acepta).
  String newId() => _newId();

  DateTime now() => _clock();

  Future<AppDatabase> database() => databases.require();

  /// [body] escribe en local y anota sus mutaciones con `sink`; todo o nada.
  Future<T> write<T>(
      Future<T> Function(AppDatabase db, MutationSink sink) body) async {
    final db = await database();
    final result = await db.transaction(
        () => body(db, MutationSink._(db, _newId, _clock)));
    onWrite?.call();
    return result;
  }
}

/// Anota mutaciones dentro de [OfflineStore.write].
class MutationSink {
  final AppDatabase _db;
  final String Function() _newId;
  final DateTime Function() _clock;

  MutationSink._(this._db, this._newId, this._clock);

  Future<void> add({
    required String type,
    required String entity,
    String? entityId,
    Map<String, dynamic> payload = const {},
  }) =>
      OutboxStore.enqueue(
        _db,
        mutationId: _newId(),
        type: type,
        entity: entity,
        entityId: entityId,
        payload: payload,
        clientTime: _clock(),
      );
}
