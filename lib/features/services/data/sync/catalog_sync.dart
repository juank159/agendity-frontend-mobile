import 'package:login_signup/core/database/app_database.dart';
import 'package:login_signup/core/database/document_store.dart';
import 'package:login_signup/core/sync/document_sync_handler.dart';
import 'package:login_signup/core/sync/outbox_store.dart';
import 'package:login_signup/features/services/data/datasources/catalog_local_datasource.dart';

/// Operaciones `service.*` y `category.*` (10.02b) y cómo se aplican en local:
/// el repositorio al escribir y el motor al reaplicar tras una bajada usan
/// [apply].
abstract final class CatalogSync {
  static const serviceCreate = 'service.create';
  static const serviceUpdate = 'service.update';
  static const serviceDelete = 'service.delete';
  static const categoryCreate = 'category.create';
  static const categoryUpdate = 'category.update';
  static const categoryDelete = 'category.delete';

  /// Aplica en local una mutación del catálogo. [extra] son campos que no
  /// viajan pero el registro local necesita (fechas, `isActive` al crear).
  static Future<void> apply(AppDatabase db, OutboxEntry entry,
      {Map<String, dynamic> extra = const {}}) async {
    final id = entry.entityId;
    if (id == null) return;
    final kind = entry.entity == CatalogDocs.categories.entity
        ? CatalogDocs.categories
        : CatalogDocs.services;
    await DocumentStore.keepServerCopy(db, kind.entity, id);
    switch (entry.type) {
      case serviceCreate:
      case categoryCreate:
        await DocumentStore.merge(
            db, kind, id, {'isActive': true, ...entry.payload, ...extra});
      case serviceUpdate:
      case categoryUpdate:
        await DocumentStore.merge(db, kind, id, {...entry.payload, ...extra});
      case serviceDelete:
      case categoryDelete:
        await DocumentStore.delete(db, kind.entity, id);
    }
  }

  static List<DocumentSyncHandler> handlers() => [
        DocumentSyncHandler(CatalogDocs.services, applyLocal: apply),
        DocumentSyncHandler(CatalogDocs.categories, applyLocal: apply),
      ];
}
