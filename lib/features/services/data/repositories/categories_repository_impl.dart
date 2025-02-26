import 'package:flutter/material.dart';
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
      debugPrint('Repository: obteniendo categorías');
      return await remoteDataSource.getCategories();
    } catch (e) {
      debugPrint('Repository error (getCategories): $e');
      rethrow;
    }
  }

  @override
  Future<void> createCategory(CategoryEntity category) async {
    try {
      debugPrint('Repository: creando categoría ${category.name}');
      final categoryModel = CategoryModel(
        id: '', // El backend generará el ID
        name: category.name,
        description: category.description,
      );
      await remoteDataSource.createCategory(categoryModel);
      debugPrint('Repository: categoría creada exitosamente');
    } catch (e) {
      debugPrint('Repository error (createCategory): $e');
      rethrow;
    }
  }

  @override
  Future<void> updateCategoryStatus(String id, bool isActive) async {
    try {
      debugPrint(
          'Repository: actualizando estado de categoría $id a $isActive');
      await remoteDataSource.updateCategoryStatus(id, isActive);
      debugPrint('Repository: estado de categoría actualizado');
    } catch (e) {
      debugPrint('Repository error (updateCategoryStatus): $e');
      rethrow;
    }
  }

  @override
  Future<void> updateCategory(
      String id, String name, String description) async {
    try {
      debugPrint('Repository: actualizando categoría $id');
      await remoteDataSource.updateCategory(id, name, description);
      debugPrint('Repository: categoría actualizada');
    } catch (e) {
      debugPrint('Repository error (updateCategory): $e');
      rethrow;
    }
  }
}
