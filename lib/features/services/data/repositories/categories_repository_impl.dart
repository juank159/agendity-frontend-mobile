import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/network/safe_call.dart';
import 'package:login_signup/core/sync/offline_store.dart';
import 'package:login_signup/features/services/data/datasources/catalog_local_datasource.dart';
import 'package:login_signup/features/services/data/sync/catalog_sync.dart';
import 'package:login_signup/features/services/domain/entities/category.dart';
import 'package:login_signup/features/services/domain/failures/services_failures.dart';
import 'package:login_signup/features/services/domain/repositories/categories_repository.dart';

/// Categorías sin conexión (10.02b): lectura local; escrituras a local +
/// bandeja (`category.*`). Nombre repetido y "tiene servicios" se avisan
/// con lo local.
class CategoriesRepositoryImpl implements CategoriesRepository {
  final OfflineStore _store;
  final CatalogLocalDataSource _local;

  CategoriesRepositoryImpl(this._store,
      {CatalogLocalDataSource local = const CatalogLocalDataSource()})
      : _local = local;

  static const _entity = 'categories';

  @override
  Future<Either<Failure, List<CategoryEntity>>> getCategories() =>
      safeCall(() async => _local.categories(await _store.database()));

  @override
  Future<Either<Failure, CategoryEntity>> createCategory({
    required String name,
    String description = '',
  }) =>
      OfflineStore.guard(() async {
        final db = await _store.database();
        if (await _local.nameTaken(db, _entity, name)) {
          return const Left(DuplicateCategoryNameFailure());
        }
        final id = _store.newId();
        await _write(CatalogSync.categoryCreate, id,
            {'name': name, 'description': description},
            extra: {'createdAt': _store.nowIso(), 'updatedAt': _store.nowIso()});
        return Right((await _local.category(db, id))!);
      });

  @override
  Future<Either<Failure, CategoryEntity>> updateCategory({
    required String id,
    required String name,
    String description = '',
  }) =>
      OfflineStore.guard(() async {
        final db = await _store.database();
        final current = await _local.category(db, id);
        if (current == null) return const Left(NotFoundFailure());
        if (await _local.nameTaken(db, _entity, name, exceptId: id)) {
          return const Left(DuplicateCategoryNameFailure());
        }
        final changes = {
          if (current.name != name) 'name': name,
          if (current.description != description) 'description': description,
        };
        if (changes.isEmpty) return Right(current);
        await _write(CatalogSync.categoryUpdate, id, changes,
            extra: {'updatedAt': _store.nowIso()});
        return Right((await _local.category(db, id))!);
      });

  @override
  Future<Either<Failure, CategoryEntity>> updateCategoryStatus({
    required String id,
    required bool isActive,
  }) =>
      OfflineStore.guard(() async {
        final db = await _store.database();
        final current = await _local.category(db, id);
        if (current == null) return const Left(NotFoundFailure());
        if (current.isActive == isActive) return Right(current);
        await _write(CatalogSync.categoryUpdate, id, {'isActive': isActive},
            extra: {'updatedAt': _store.nowIso()});
        return Right((await _local.category(db, id))!);
      });

  /// Con servicios (activos o no) no se borra: FK RESTRICT en el servidor.
  @override
  Future<Either<Failure, Unit>> deleteCategory(String id) =>
      OfflineStore.guard(() async {
        final db = await _store.database();
        final current = await _local.category(db, id);
        if (current == null) return const Left(NotFoundFailure());
        if ((current.serviceCount ?? 0) > 0) {
          return const Left(CategoryHasServicesFailure());
        }
        await _write(CatalogSync.categoryDelete, id, const {});
        return const Right(unit);
      });

  Future<void> _write(String type, String id, Map<String, dynamic> payload,
          {Map<String, dynamic> extra = const {}}) =>
      _store.write((db, sink) async {
        final entry = await sink.add(
            type: type, entity: _entity, entityId: id, payload: payload);
        await CatalogSync.apply(db, entry, extra: extra);
      });
}
