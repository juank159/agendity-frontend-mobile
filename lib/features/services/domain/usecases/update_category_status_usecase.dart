import '../repositories/categories_repository.dart';

class UpdateCategoryStatusUseCase {
  final CategoriesRepository repository;

  UpdateCategoryStatusUseCase(this.repository);

  Future<void> execute(String id, bool isActive) async {
    await repository.updateCategoryStatus(id, isActive);
  }
}
