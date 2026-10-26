import 'package:dio/dio.dart';
import 'package:login_signup/features/services/data/models/category_model.dart';

/// Rutas `/categories`. Los errores (400/403/404/409, red) salen como
/// `DioException` y los traduce `safeCall` en el repositorio.
abstract class CategoriesRemoteDataSource {
  /// `GET /categories` (Owner y Employee): todas, con sus `services`.
  Future<List<CategoryModel>> getCategories();

  /// `POST /categories` (solo Owner). Responde 201 con la categoría.
  Future<CategoryModel> createCategory(CategoryModel category);

  /// `PATCH /categories/:id` con nombre y descripción (solo Owner).
  Future<CategoryModel> updateCategory(String id, CategoryModel category);

  /// `PATCH /categories/:id` con solo `isActive` (cambio parcial).
  Future<CategoryModel> updateCategoryStatus(String id, bool isActive);

  /// `DELETE /categories/:id` (solo Owner). Con servicios: 409
  /// `CATEGORY_HAS_SERVICES`.
  Future<void> deleteCategory(String id);
}

class CategoriesRemoteDataSourceImpl implements CategoriesRemoteDataSource {
  final Dio _dio;

  /// Debe ser el Dio `tag: apiClientTag` (token y errores del núcleo).
  CategoriesRemoteDataSourceImpl(this._dio);

  @override
  Future<List<CategoryModel>> getCategories() async {
    final response = await _dio.get<List<dynamic>>('/categories');
    return response.data!
        .cast<Map<String, dynamic>>()
        .map(CategoryModel.fromJson)
        .toList();
  }

  @override
  Future<CategoryModel> createCategory(CategoryModel category) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/categories',
      data: category.toJson(),
    );
    return CategoryModel.fromJson(response.data!);
  }

  @override
  Future<CategoryModel> updateCategory(
      String id, CategoryModel category) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/categories/$id',
      data: category.toJson(),
    );
    return CategoryModel.fromJson(response.data!);
  }

  @override
  Future<CategoryModel> updateCategoryStatus(String id, bool isActive) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/categories/$id',
      data: {'isActive': isActive},
    );
    return CategoryModel.fromJson(response.data!);
  }

  @override
  Future<void> deleteCategory(String id) async {
    await _dio.delete<void>('/categories/$id');
  }
}
