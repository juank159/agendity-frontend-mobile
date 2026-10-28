import 'package:login_signup/core/utils/json_read.dart';
import 'package:login_signup/features/settings/domain/entities/business_settings.dart';

/// DTO de `GET`/`PATCH /settings` (`{timezone}`).
class BusinessSettingsModel {
  final String timeZone;

  const BusinessSettingsModel({required this.timeZone});

  /// Sin `timezone` no es una respuesta válida (`FormatException` →
  /// `ServerFailure`).
  factory BusinessSettingsModel.fromJson(Map<String, dynamic>? json) {
    final timeZone = JsonRead.asOptionalString(json?['timezone']);
    if (timeZone == null) {
      throw const FormatException('Configuración del negocio sin zona');
    }
    return BusinessSettingsModel(timeZone: timeZone);
  }

  /// Cuerpo de `PATCH /settings` (`UpdateSettingsDto`).
  static Map<String, dynamic> timeZoneUpdate(String timeZone) =>
      {'timezone': timeZone};

  BusinessSettings toEntity() => BusinessSettings(timeZone: timeZone);
}
