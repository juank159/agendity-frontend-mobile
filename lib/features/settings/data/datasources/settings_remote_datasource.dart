import 'package:dio/dio.dart';
import 'package:login_signup/features/settings/data/models/business_settings_model.dart';

/// `/settings` sobre el Dio `api` (con el token de la sesión). Sin
/// try/catch: los errores los traduce `safeCall`.
abstract class SettingsRemoteDataSource {
  /// `GET /settings`.
  Future<BusinessSettingsModel> getSettings();

  /// `PATCH /settings {timezone}` (solo Owner).
  Future<BusinessSettingsModel> updateTimeZone(String timeZone);
}

class SettingsRemoteDataSourceImpl implements SettingsRemoteDataSource {
  final Dio _dio;

  SettingsRemoteDataSourceImpl(this._dio);

  @override
  Future<BusinessSettingsModel> getSettings() async {
    final response = await _dio.get<Map<String, dynamic>>('/settings');
    return BusinessSettingsModel.fromJson(response.data);
  }

  @override
  Future<BusinessSettingsModel> updateTimeZone(String timeZone) async {
    final response = await _dio.patch<Map<String, dynamic>>('/settings',
        data: BusinessSettingsModel.timeZoneUpdate(timeZone));
    return BusinessSettingsModel.fromJson(response.data);
  }
}
