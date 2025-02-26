import '../entities/category.dart';

abstract class CategoriesRepository {
  Future<List<CategoryEntity>> getCategories();
  Future<void> createCategory(CategoryEntity category);
  Future<void> updateCategoryStatus(String id, bool isActive);
  Future<void> updateCategory(String id, String name, String description);
}
