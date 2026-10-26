import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/features/services/domain/entities/category.dart';
import 'package:login_signup/features/services/domain/repositories/categories_repository.dart';
import 'package:login_signup/features/services/domain/usecases/catalog_rules.dart';

class CategoryParams {
  final String name;
  final String description;

  const CategoryParams({required this.name, this.description = ''});
}

/// Crea una categoría (solo Owner). Nombre obligatorio (≤ 100); repetido →
/// `DuplicateCategoryNameFailure`.
class CreateCategoryUseCase extends UseCase<CategoryEntity, CategoryParams> {
  final CategoriesRepository repository;

  CreateCategoryUseCase(this.repository);

  @override
  Future<Either<Failure, CategoryEntity>> call(CategoryParams params) async {
    final invalid = CatalogRules.checkCategoryName(params.name);
    if (invalid != null) return Left(invalid);
    return repository.createCategory(
      name: params.name.trim(),
      description: params.description.trim(),
    );
  }
}
