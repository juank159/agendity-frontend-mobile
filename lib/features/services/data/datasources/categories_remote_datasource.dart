import 'package:dio/dio.dart';
import '../models/category_model.dart';
import '../../../../shared/local_storage/local_storage.dart';

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

      if (response.statusCode == 200 && response.data != null) {
        return (response.data as List)
            .map((json) => CategoryModel.fromJson(json))
            .toList();
      }

      throw Exception('Failed to load categories');
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('No autorizado');
      }
      throw Exception('Error al cargar las categorías: ${e.message}');
    }
  }
}
