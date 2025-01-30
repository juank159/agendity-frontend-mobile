// import '../../domain/entities/category.dart';
// import '../../domain/repositories/categories_repository.dart';
// import '../datasources/categories_remote_datasource.dart';

// class CategoriesRepositoryImpl implements CategoriesRepository {
//   final CategoriesRemoteDataSource remoteDataSource;

//   CategoriesRepositoryImpl({required this.remoteDataSource});

//   @override
//   Future<List<Category>> getCategories() async {
//     try {
//       return await remoteDataSource.getCategories();
//     } catch (e) {
//       rethrow;
//     }
//   }
// }

// lib/features/categories/data/repositories/categories_repository_impl.dart
import '../../domain/entities/category.dart';
import '../../domain/repositories/categories_repository.dart';
import '../datasources/categories_remote_datasource.dart';
import '../models/category_model.dart';

class CategoriesRepositoryImpl implements CategoriesRepository {
  final CategoriesRemoteDataSource remoteDataSource;

  CategoriesRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<CategoryEntity>> getCategories() async {
    try {
      return await remoteDataSource.getCategories();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> createCategory(CategoryEntity category) async {
    try {
      final categoryModel = CategoryModel(
        id: '',
        name: category.name,
        description: category.description,
      );
      await remoteDataSource.createCategory(categoryModel);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> updateCategoryStatus(String id, bool isActive) async {
    try {
      await remoteDataSource.updateCategoryStatus(id, isActive);
    } catch (e) {
      rethrow;
    }
  }
}
