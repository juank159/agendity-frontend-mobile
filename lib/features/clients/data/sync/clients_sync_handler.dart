import 'package:login_signup/core/database/app_database.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/network/error_mapper.dart';
import 'package:login_signup/core/sync/outbox_store.dart';
import 'package:login_signup/core/sync/sync_entity_handler.dart';
import 'package:login_signup/features/clients/data/datasources/clients_local_datasource.dart';
import 'package:login_signup/features/clients/data/datasources/clients_remote_datasource.dart';

/// Entidad `clients` del feed y sus mutaciones `client.create/import/update/
/// delete`.
class ClientsSyncHandler extends SyncEntityHandler {
  static const entityName = 'clients';
  static const create = 'client.create';

  /// Contacto importado del teléfono (backend `0c3b0af`): como una fila de
  /// `POST /clients/batch`, queda con `isFromDevice: true`.
  static const import = 'client.import';
  static const update = 'client.update';
  static const remove = 'client.delete';

  final ClientsLocalDataSource _local;

  /// Para [restore] (`GET /clients/:id`); `null` = no restaura (tests).
  final ClientsRemoteDataSource? _remote;

  ClientsSyncHandler(this._local, [this._remote]);

  @override
  String get entity => entityName;

  @override
  Future<void> upsert(AppDatabase db, String id, Map<String, dynamic> data) =>
      _local.upsertFields(db, id, data);

  @override
  Future<void> delete(AppDatabase db, String id) => _local.delete(db, id);

  @override
  Future<void> replay(AppDatabase db, OutboxEntry entry) async {
    final id = entry.entityId;
    if (id == null) return;
    switch (entry.type) {
      case create:
      case update:
        await _local.upsertFields(db, id, entry.payload);
      case import:
        await _local.upsertFields(
            db, id, {...entry.payload, 'isFromDevice': true});
      case remove:
        await _local.delete(db, id);
    }
  }

  @override
  Future<void> remap(
      AppDatabase db, String entity, String fromId, String toId) async {
    if (entity == entityName) await _local.remap(db, fromId, toId);
  }

  @override
  Future<void> restore(AppDatabase db, String id) async {
    final remote = _remote;
    if (remote == null) return;
    try {
      await _local.upsertFields(db, id, await remote.fetchClient(id));
    } catch (error) {
      if (ErrorMapper.fromObject(error) is NotFoundFailure) {
        await _local.delete(db, id); // no existe en el servidor
      } else {
        rethrow;
      }
    }
  }
}
