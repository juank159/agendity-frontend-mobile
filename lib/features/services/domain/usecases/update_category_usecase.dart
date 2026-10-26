import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/features/services/domain/entities/category.dart';
import 'package:login_signup/features/services/domain/repositories/categories_repository.dart';
import 'package:login_signup/features/services/domain/usecases/catalog_rules.dart';

class UpdateCategoryParams {
  final String id;
  final String name;
  final String description;

  const UpdateCategoryParams({
    required this.id,
    required this.name,
    this.description = '',
  });
}

/// Renombra o cambia la descripción de una categoría (solo Owner). Nombre
/// repetido → `DuplicateCategoryNameFailure`.
class UpdateCategoryUseCase
    extends UseCase<CategoryEntity, UpdateCategoryParams> {
  final CategoriesRepository repository;

  UpdateCategoryUseCase(this.repository);

  @override
  Future<Either<Failure, CategoryEntity>> call(
      UpdateCategoryParams params) async {
    final invalid = CatalogRules.checkCategoryName(params.name);
    if (invalid != null) return Left(invalid);
    return repository.updateCategory(
      id: params.id,
      name: params.name.trim(),
      description: params.description.trim(),
    );
  }
}
