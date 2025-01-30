import 'package:dio/dio.dart';
import '../../../../shared/local_storage/local_storage.dart';
import '../../domain/entities/service_entity.dart';

class ServicesRemoteDataSource {
  final Dio dio;
  final LocalStorage localStorage;

  ServicesRemoteDataSource({
    required this.dio,
    required this.localStorage,
  });

  Future<List<Map<String, dynamic>>> getServices() async {
    try {
      final token = await localStorage.getToken();

      final response = await dio.get(
        '/services',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        return List<Map<String, dynamic>>.from(response.data);
      }

      throw Exception('Failed to load services');
    } catch (e) {
      throw Exception('Error loading services: $e');
    }
  }

  Future<void> createService(ServiceEntity service) async {
    try {
      final token = await localStorage.getToken();

      await dio.post(
        '/services',
        data: service.toJson(),
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );
    } catch (e) {
      throw Exception('Error creating service: $e');
    }
  }

  // actualizar servicio

  Future<void> updateService(String id, ServiceEntity service) async {
    try {
      final token = await localStorage.getToken();
      await dio.patch(
        '/services/$id',
        data: service.toJson(),
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } catch (e) {
      throw Exception('Error updating service: $e');
    }
  }

  Future<void> deleteService(String id) async {
    try {
      final token = await localStorage.getToken();
      await dio.delete(
        '/services/$id',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } catch (e) {
      throw Exception('Error deleting service: $e');
    }
  }
}
