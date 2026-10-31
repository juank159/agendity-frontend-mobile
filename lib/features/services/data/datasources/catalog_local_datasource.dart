import 'package:login_signup/core/database/app_database.dart';
import 'package:login_signup/core/database/document_store.dart';
import 'package:login_signup/core/database/shared_documents.dart';
import 'package:login_signup/core/utils/json_read.dart';
import 'package:login_signup/features/services/data/models/category_model.dart';
import 'package:login_signup/features/services/data/models/service_model.dart';
import 'package:login_signup/features/services/domain/entities/category.dart';
import 'package:login_signup/features/services/domain/entities/service_entity.dart';

/// Catálogo en la base local (10.02b): servicios y categorías con la forma de
/// la API (feeds `services` y `categories`).
abstract final class CatalogDocs {
  static final services = DocumentKind('services',
      ref1: (d) => JsonRead.asOptionalString(d['categoryId']));
  static const categories = DocumentKind('categories');
}

/// Lecturas del catálogo (sin red).
class CatalogLocalDataSource {
  const CatalogLocalDataSource();

  /// Servicios (con su categoría), ordenados por nombre. Por defecto solo
  /// los activos, como `GET /services`.
  Future<List<ServiceEntity>> services(AppDatabase db,
      {bool includeInactive = false}) async {
    final categories = {
      for (final c in await DocumentStore.list(db, CatalogDocs.categories.entity))
        c['id']: c,
    };
    final services = [
      for (final s in await DocumentStore.list(db, CatalogDocs.services.entity))
        if (includeInactive || JsonRead.asBool(s['isActive'], fallback: true))
          ServiceModel.fromJson({
            ...s,
            if (categories[s['categoryId']] case final category?)
              'category': category,
          }).toEntity(),
    ];
    return services
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  Future<ServiceEntity?> service(AppDatabase db, String id) async {
    final all = await services(db, includeInactive: true);
    return all.where((s) => s.id == id).firstOrNull;
  }

  /// Todas las categorías (activas o no) con `serviceCount`, por nombre.
  Future<List<CategoryEntity>> categories(AppDatabase db) async {
    final services =
        await DocumentStore.list(db, CatalogDocs.services.entity);
    final categories = [
      for (final c
          in await DocumentStore.list(db, CatalogDocs.categories.entity))
        CategoryModel.fromJson({
          ...c,
          'services': [
            for (final s in services)
              if (s['categoryId'] == c['id']) s['id'],
          ],
        }).toEntity(),
    ];
    return categories
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  Future<CategoryEntity?> category(AppDatabase db, String id) async =>
      (await categories(db)).where((c) => c.id == id).firstOrNull;

  /// Servicios activos que hace [professionalId] (equivalente local de
  /// `GET /auth/me/services`, 7.04): el Owner, todos; un empleado, los que
  /// tiene asignados y activos.
  Future<List<ServiceEntity>> offeredBy(
      AppDatabase db, String professionalId) async {
    final active = await services(db);
    final user =
        await DocumentStore.get(db, SharedDocs.users.entity, professionalId);
    if (user != null && SharedDocs.isOwner(user)) return active;
    final assigned = {
      for (final row in await DocumentStore.list(
          db, SharedDocs.userServices.entity,
          ref1: professionalId))
        if (JsonRead.asBool(row['isActive'], fallback: true)) row['serviceId'],
    };
    return [for (final s in active) if (assigned.contains(s.id)) s];
  }

  /// Nombre ya usado por otro registro de [entity] (sin mayúsculas).
  Future<bool> nameTaken(AppDatabase db, String entity, String name,
      {String? exceptId}) async {
    final wanted = name.trim().toLowerCase();
    return (await DocumentStore.list(db, entity)).any((d) =>
        d['id'] != exceptId &&
        JsonRead.asString(d['name']).trim().toLowerCase() == wanted);
  }
}
