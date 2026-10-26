import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/features/services/domain/repositories/categories_repository.dart';

/// Borra una categoría por id (solo Owner). Si tiene servicios, el backend lo
/// impide → `CategoryHasServicesFailure`.
class DeleteCategoryUseCase extends UseCase<Unit, String> {
  final CategoriesRepository repository;

  DeleteCategoryUseCase(this.repository);

  @override
  Future<Either<Failure, Unit>> call(String params) =>
      repository.deleteCategory(params);
}
