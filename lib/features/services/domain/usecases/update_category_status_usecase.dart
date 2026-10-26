import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/features/services/domain/entities/category.dart';
import 'package:login_signup/features/services/domain/repositories/categories_repository.dart';

class UpdateCategoryStatusParams {
  final String id;
  final bool isActive;

  const UpdateCategoryStatusParams({required this.id, required this.isActive});
}

/// Activa o desactiva una categoría (solo Owner).
class UpdateCategoryStatusUseCase
    extends UseCase<CategoryEntity, UpdateCategoryStatusParams> {
  final CategoriesRepository repository;

  UpdateCategoryStatusUseCase(this.repository);

  @override
  Future<Either<Failure, CategoryEntity>> call(
          UpdateCategoryStatusParams params) =>
      repository.updateCategoryStatus(id: params.id, isActive: params.isActive);
}
