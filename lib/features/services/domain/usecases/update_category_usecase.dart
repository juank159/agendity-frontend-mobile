import '../repositories/categories_repository.dart';

class UpdateCategoryUseCase {
  final CategoriesRepository repository;

  UpdateCategoryUseCase(this.repository);

  Future<void> execute(String id, String name, String description) async {
    await repository.updateCategory(id, name, description);
  }
}
