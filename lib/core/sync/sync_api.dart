import 'package:dio/dio.dart';
import 'package:login_signup/core/sync/sync_models.dart';

/// Red del motor de sincronización (inyectable: los tests la simulan).
abstract class SyncApi {
  /// `POST /sync/push`. Lanza si no hubo respuesta (sin red, 5xx…): entonces
  /// nada del lote se da por enviado.
  Future<List<MutationResult>> push(
      String deviceId, List<PushMutation> mutations);

  /// `GET /sync/changes?cursor=&limit=`.
  Future<ChangesPage> changes(String cursor, {int limit = 500});
}

/// [SyncApi] sobre el Dio `api` (token del núcleo).
class DioSyncApi implements SyncApi {
  final Dio _dio;

  DioSyncApi(this._dio);

  @override
  Future<List<MutationResult>> push(
      String deviceId, List<PushMutation> mutations) async {
    final response = await _dio.post<Map<String, dynamic>>('/sync/push', data: {
      'device_id': deviceId,
      'mutations': [for (final m in mutations) m.toJson()],
    });
    return [
      for (final raw in (response.data?['results'] as List? ?? const []))
        if (raw is Map) MutationResult.fromJson(Map<String, dynamic>.from(raw)),
    ];
  }

  @override
  Future<ChangesPage> changes(String cursor, {int limit = 500}) async {
    final response = await _dio.get<Map<String, dynamic>>('/sync/changes',
        queryParameters: {'cursor': cursor, 'limit': limit});
    return ChangesPage.fromJson(response.data ?? const {}, cursor);
  }
}
