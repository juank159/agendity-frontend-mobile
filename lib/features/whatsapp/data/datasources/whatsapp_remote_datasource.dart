import 'package:dio/dio.dart';
import 'package:login_signup/features/whatsapp/data/models/whatsapp_config_model.dart';

/// Rutas `/whatsapp/*`. Los errores (403 al Employee, 404 sin configuración,
/// red) salen como `DioException` y los traduce `safeCall` en el repositorio.
abstract class WhatsappRemoteDataSource {
  /// 404 `NOT_FOUND` si el negocio no tiene configuración.
  Future<WhatsappConfigModel> getConfig();
  Future<WhatsappConfigModel> saveConfig(WhatsappConfigModel config);

  /// El backend responde 200/201 con `{success, message}`; no lanza si
  /// CallMeBot falla.
  Future<bool> sendTestMessage();
  Future<bool> sendMessage(String phoneNumber, String message);
}

class WhatsappRemoteDataSourceImpl implements WhatsappRemoteDataSource {
  final Dio _dio;

  /// Debe ser el Dio `tag: apiClientTag` (token y errores del núcleo).
  WhatsappRemoteDataSourceImpl(this._dio);

  @override
  Future<WhatsappConfigModel> getConfig() async {
    final response = await _dio.get<Map<String, dynamic>>('/whatsapp/config');
    return WhatsappConfigModel.fromJson(response.data!);
  }

  @override
  Future<WhatsappConfigModel> saveConfig(WhatsappConfigModel config) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/whatsapp/config',
      data: config.toJson(),
    );
    return WhatsappConfigModel.fromJson(response.data!);
  }

  @override
  Future<bool> sendTestMessage() async {
    final response = await _dio.post<dynamic>('/whatsapp/test');
    return _succeeded(response.data);
  }

  @override
  Future<bool> sendMessage(String phoneNumber, String message) async {
    final response = await _dio.post<dynamic>(
      '/whatsapp/send',
      data: {'phoneNumber': phoneNumber, 'message': message},
    );
    return _succeeded(response.data);
  }

  static bool _succeeded(Object? data) =>
      data is Map && data['success'] == true;
}
