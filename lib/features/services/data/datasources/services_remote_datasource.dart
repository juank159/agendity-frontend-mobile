import 'package:dio/dio.dart';
import 'package:login_signup/features/services/data/models/service_model.dart';

/// Rutas `/services`. Los errores (400/403/404/409, red) salen como
/// `DioException` y los traduce `safeCall` en el repositorio.
abstract class ServicesRemoteDataSource {
  /// `GET /services` (Owner y Employee): solo los activos, con `category`.
  Future<List<ServiceModel>> getServices();

  /// `POST /services` (solo Owner). Responde 201 con el servicio creado.
  Future<ServiceModel> createService(ServiceModel service);

  /// `PATCH /services/:id` (solo Owner; cambios parciales). Responde 200.
  Future<ServiceModel> updateService(String id, ServiceModel service);

  /// `DELETE /services/:id` (solo Owner). Responde 200 sin cuerpo.
  Future<void> deleteService(String id);
}

class ServicesRemoteDataSourceImpl implements ServicesRemoteDataSource {
  final Dio _dio;

  /// Debe ser el Dio `tag: apiClientTag` (token y errores del núcleo).
  ServicesRemoteDataSourceImpl(this._dio);

  @override
  Future<List<ServiceModel>> getServices() async {
    final response = await _dio.get<List<dynamic>>('/services');
    return response.data!
        .cast<Map<String, dynamic>>()
        .map(ServiceModel.fromJson)
        .toList();
  }

  @override
  Future<ServiceModel> createService(ServiceModel service) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/services',
      data: service.toJson(),
    );
    return ServiceModel.fromJson(response.data!);
  }

  @override
  Future<ServiceModel> updateService(String id, ServiceModel service) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/services/$id',
      data: service.toJson(),
    );
    return ServiceModel.fromJson(response.data!);
  }

  @override
  Future<void> deleteService(String id) async {
    await _dio.delete<void>('/services/$id');
  }
}
