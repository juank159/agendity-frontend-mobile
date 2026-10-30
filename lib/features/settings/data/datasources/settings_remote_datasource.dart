import 'package:dio/dio.dart';
import 'package:login_signup/features/settings/data/models/business_settings_model.dart';

/// `/settings` sobre el Dio `api` (con el token de la sesión). Sin
/// try/catch: los errores los traduce `safeCall`.
abstract class SettingsRemoteDataSource {
  /// `GET /settings`.
  Future<BusinessSettingsModel> getSettings();

  /// `PATCH /settings` con solo los campos que cambian (solo Owner). El
  /// cuerpo lo arma `BusinessSettingsModel` (`timeZoneUpdate`, `nameUpdate`,
  /// `openingHoursUpdate`).
  Future<BusinessSettingsModel> update(Map<String, dynamic> changes);
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
  Future<BusinessSettingsModel> update(Map<String, dynamic> changes) async {
    final response =
        await _dio.patch<Map<String, dynamic>>('/settings', data: changes);
    return BusinessSettingsModel.fromJson(response.data);
  }
}
