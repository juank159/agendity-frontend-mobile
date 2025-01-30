import 'package:dio/dio.dart';
import '../../../../shared/local_storage/local_storage.dart';
import '../models/category_model.dart';

class CategoriesRemoteDataSource {
  final Dio dio;
  final LocalStorage localStorage;

  CategoriesRemoteDataSource({
    required this.dio,
    required this.localStorage,
  });

  Future<List<CategoryModel>> getCategories() async {
    try {
      final token = await localStorage.getToken();

      final response = await dio.get(
        '/categories',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200) {
        return (response.data as List)
            .map((json) => CategoryModel.fromJson(json))
            .toList();
      }

      throw Exception('Failed to load categories');
    } catch (e) {
      throw Exception('Error loading categories: $e');
    }
  }

  Future<void> createCategory(CategoryModel category) async {
    try {
      final token = await localStorage.getToken();

      await dio.post(
        '/categories',
        data: category.toJson(),
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );
    } catch (e) {
      throw Exception('Error creating category: $e');
    }
  }

  Future<void> updateCategoryStatus(String id, bool isActive) async {
    try {
      final token = await localStorage.getToken();

      await dio.patch(
        '/categories/$id',
        data: {'isActive': isActive},
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );
    } catch (e) {
      throw Exception('Error updating category status: $e');
    }
  }
}
