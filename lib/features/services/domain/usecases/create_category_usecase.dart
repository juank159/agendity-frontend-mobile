import '../entities/category.dart';
import '../repositories/categories_repository.dart';

class CreateCategoryUseCase {
  final CategoriesRepository repository;

  CreateCategoryUseCase(this.repository);

  Future<void> execute(CategoryEntity category) async {
    await repository.createCategory(category);
  }
}
