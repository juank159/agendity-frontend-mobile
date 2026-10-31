import 'package:login_signup/core/database/app_database.dart';
import 'package:login_signup/core/database/document_store.dart';
import 'package:login_signup/core/sync/outbox_store.dart';
import 'package:login_signup/core/sync/sync_entity_handler.dart';

/// Handler de una entidad guardada en `LocalDocuments` (10.02b): la bajada
/// guarda el registro tal como llega. Las features que suben cambios pasan
/// [applyLocal] (lo mismo que hace su repositorio al escribir sin conexión)
/// y, si hace falta, [onRemap]. Deshacer un rechazo vuelve a la copia del
/// servidor (`DocumentStore.keepServerCopy`, que hace `applyLocal`).
class DocumentSyncHandler extends SyncEntityHandler {
  final DocumentKind kind;
  final Future<void> Function(AppDatabase db, OutboxEntry entry)? applyLocal;
  final Future<void> Function(
      AppDatabase db, String entity, String fromId, String toId)? onRemap;
  final Future<void> Function(AppDatabase db, String id)? onRestore;

  DocumentSyncHandler(this.kind,
      {this.applyLocal, this.onRemap, this.onRestore});

  @override
  String get entity => kind.entity;

  @override
  Future<void> upsert(
      AppDatabase db, String id, Map<String, dynamic> data) async {
    await DocumentStore.put(db, kind, id, data);
    await DocumentStore.dropServerCopy(db, kind.entity, id);
  }

  @override
  Future<void> delete(AppDatabase db, String id) async {
    await DocumentStore.delete(db, kind.entity, id);
    await DocumentStore.dropServerCopy(db, kind.entity, id);
  }

  @override
  Future<void> replay(AppDatabase db, OutboxEntry entry) async =>
      applyLocal?.call(db, entry);

  @override
  Future<void> remap(AppDatabase db, String entity, String fromId,
          String toId) async =>
      onRemap?.call(db, entity, fromId, toId);

  /// Por defecto, vuelve a la copia del servidor guardada antes de la
  /// escritura local (`DocumentStore.keepServerCopy`).
  @override
  Future<void> restore(AppDatabase db, String id) async {
    if (onRestore != null) return onRestore!(db, id);
    await DocumentStore.restoreServerCopy(db, kind, id);
  }
}
