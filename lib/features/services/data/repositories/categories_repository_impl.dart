import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/network/safe_call.dart';
import 'package:login_signup/features/services/data/datasources/categories_remote_datasource.dart';
import 'package:login_signup/features/services/data/models/category_model.dart';
import 'package:login_signup/features/services/domain/entities/category.dart';
import 'package:login_signup/features/services/domain/failures/services_failures.dart';
import 'package:login_signup/features/services/domain/repositories/categories_repository.dart';

class CategoriesRepositoryImpl implements CategoriesRepository {
  final CategoriesRemoteDataSource _remote;

  CategoriesRepositoryImpl(this._remote);

  @override
  Future<Either<Failure, List<CategoryEntity>>> getCategories() =>
      safeCall(() async =>
          (await _remote.getCategories()).map((m) => m.toEntity()).toList());

  @override
  Future<Either<Failure, CategoryEntity>> createCategory({
    required String name,
    String description = '',
  }) =>
      safeCall(
        () async => (await _remote.createCategory(
                CategoryModel(id: '', name: name, description: description)))
            .toEntity(),
        refine: _refineSave,
      );

  @override
  Future<Either<Failure, CategoryEntity>> updateCategory({
    required String id,
    required String name,
    String description = '',
  }) =>
      safeCall(
        () async => (await _remote.updateCategory(id,
                CategoryModel(id: id, name: name, description: description)))
            .toEntity(),
        refine: _refineSave,
      );

  @override
  Future<Either<Failure, CategoryEntity>> updateCategoryStatus({
    required String id,
    required bool isActive,
  }) =>
      safeCall(() async =>
          (await _remote.updateCategoryStatus(id, isActive)).toEntity());

  @override
  Future<Either<Failure, Unit>> deleteCategory(String id) => safeCall(
        () async {
          await _remote.deleteCategory(id);
          return unit;
        },
        refine: _refineDelete,
      );

  /// Al crear o renombrar, el 409 `CONFLICT` es el nombre repetido.
  static Failure _refineSave(Failure failure) =>
      failure.code == ApiErrorCode.conflict
          ? DuplicateCategoryNameFailure(
              message: failure.message,
              code: failure.code,
              statusCode: failure.statusCode,
              details: failure.details,
            )
          : failure;

  /// `CATEGORY_HAS_SERVICES`, o `CONFLICT` si la FK RESTRICT frenó el borrado
  /// (un servicio creado a la vez): en los dos casos la categoría tiene
  /// servicios.
  static Failure _refineDelete(Failure failure) =>
      failure.code == ApiErrorCode.categoryHasServices ||
              failure.code == ApiErrorCode.conflict
          ? CategoryHasServicesFailure(
              message: failure.message,
              code: failure.code,
              statusCode: failure.statusCode,
              details: failure.details,
            )
          : failure;
}
