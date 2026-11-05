import 'package:dio/dio.dart';
import 'package:login_signup/features/services/data/models/my_service_model.dart';
import 'package:login_signup/features/services/domain/entities/my_service.dart';

/// Lecturas del catálogo que solo sabe el servidor. Hoy, "Mis servicios"
/// (`GET /auth/me/services`): la comisión general de la empleada no baja a
/// su teléfono con la sincronización. Los errores salen como `DioException`
/// y los traduce `safeCall` en el repositorio.
abstract class ServicesRemoteDataSource {
  Future<List<MyService>> getMyServices();
}

class ServicesRemoteDataSourceImpl implements ServicesRemoteDataSource {
  final Dio _dio;

  /// Debe ser el Dio `tag: apiClientTag` (token y errores del núcleo).
  ServicesRemoteDataSourceImpl(this._dio);

  @override
  Future<List<MyService>> getMyServices() async {
    final response = await _dio.get<List<dynamic>>('/auth/me/services');
    return [
      for (final row in response.data ?? const [])
        if (row is Map) MyServiceModel.fromJson(Map<String, dynamic>.from(row)),
    ];
  }
}
