// lib/features/services/data/datasources/services_remote_datasource.dart
import 'package:dio/dio.dart';
import 'package:login_signup/shared/local_storage/local_storage.dart';

class ServicesRemoteDataSource {
  final Dio dio;
  final LocalStorage localStorage;

  ServicesRemoteDataSource({
    required this.dio,
    required this.localStorage,
  });

  Future<List<Map<String, dynamic>>> getServices() async {
    try {
      // Obtener el token
      final token = await localStorage.getToken();

      print('Token usado: $token'); // Debug print 1
      print('URL completa: ${dio.options.baseUrl}/services'); // Debug print 2

      final response = await dio.get(
        '/services',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      print('Respuesta del servidor: ${response.data}'); // Debug print 3

      if (response.statusCode == 200 && response.data != null) {
        return List<Map<String, dynamic>>.from(response.data);
      }

      throw Exception('Failed to load services');
    } on DioException catch (e) {
      print('Error DioException: ${e.message}'); // Debug print 5
      print('Error response: ${e.response?.data}'); // Debug print 6
      if (e.response?.statusCode == 401) {
        throw Exception('No autorizado');
      }
      if (e.response?.statusCode == 404) {
        throw Exception('No se encontraron servicios');
      }
      throw Exception('Error al cargar los servicios: ${e.message}');
    }
  }
}
