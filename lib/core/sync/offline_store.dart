import 'package:dartz/dartz.dart';
import 'package:login_signup/core/database/app_database.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/network/safe_call.dart';
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

  /// Instante actual en ISO UTC (para `created_at`/`updated_at` locales).
  String nowIso() => _clock().toUtc().toIso8601String();

  /// Ejecuta un cuerpo que ya devuelve `Either` y convierte en failure lo
  /// que lance (sin sesión, base dañada…), sin propagar la excepción.
  static Future<Either<Failure, T>> guard<T>(
      Future<Either<Failure, T>> Function() body) async {
    final result = await safeCall(body);
    return result.fold(Left.new, (inner) => inner);
  }

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

  /// Anota la mutación y la devuelve (para aplicarla en local con el mismo
  /// código que la reaplica tras una bajada).
  Future<OutboxEntry> add({
    required String type,
    required String entity,
    String? entityId,
    Map<String, dynamic> payload = const {},
  }) async {
    final mutationId = _newId();
    final clientTime = _clock();
    final seq = await OutboxStore.enqueue(
      _db,
      mutationId: mutationId,
      type: type,
      entity: entity,
      entityId: entityId,
      payload: payload,
      clientTime: clientTime,
    );
    return OutboxEntry(
      seq: seq,
      mutationId: mutationId,
      type: type,
      entity: entity,
      entityId: entityId,
      payload: payload,
      clientTime: clientTime.toUtc().toIso8601String(),
    );
  }
}
