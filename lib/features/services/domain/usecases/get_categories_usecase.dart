import '../entities/category.dart';
import '../repositories/categories_repository.dart';

class GetCategoriesUseCase {
  final CategoriesRepository repository;

  GetCategoriesUseCase(this.repository);

  Future<List<CategoryEntity>> execute() async {
    return await repository.getCategories();
  }
}
