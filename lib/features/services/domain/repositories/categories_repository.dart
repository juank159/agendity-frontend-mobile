import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/features/services/domain/entities/category.dart';

/// Categorías del negocio. Leer: Owner y Employee. Escribir: solo Owner (el
/// Employee recibe `ForbiddenFailure`).
abstract class CategoriesRepository {
  /// Todas (activas o no), con `serviceCount`.
  Future<Either<Failure, List<CategoryEntity>>> getCategories();

  /// Nombre repetido → `DuplicateCategoryNameFailure`.
  Future<Either<Failure, CategoryEntity>> createCategory({
    required String name,
    String description = '',
  });

  /// Nombre repetido → `DuplicateCategoryNameFailure`.
  Future<Either<Failure, CategoryEntity>> updateCategory({
    required String id,
    required String name,
    String description = '',
  });

  Future<Either<Failure, CategoryEntity>> updateCategoryStatus({
    required String id,
    required bool isActive,
  });

  /// Con servicios → `CategoryHasServicesFailure`.
  Future<Either<Failure, Unit>> deleteCategory(String id);
}
