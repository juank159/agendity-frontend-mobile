import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:login_signup/core/utils/app_logger.dart';
import 'package:login_signup/core/utils/business_time_zone.dart';

/// Lee la zona IANA del dispositivo (`America/Bogota`), o `null`.
typedef DeviceTimeZoneReader = Future<String?> Function();

/// Zona IANA del dispositivo (paquete `flutter_timezone`: Dart solo da
/// abreviaturas como `COT`). La usa el alta de un negocio (D-15: el negocio
/// nace con la zona del teléfono de su dueño).
abstract final class DeviceTimeZone {
  /// Nombre canónico de la zona del dispositivo, o `null` si la plataforma no
  /// la da o no es una zona IANA conocida (entonces el backend usa la suya
  /// por defecto). Nunca lanza.
  static Future<String?> read() async {
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      return BusinessTimeZone.canonicalName(info.identifier);
    } catch (error) {
      AppLogger.error('Zona del dispositivo', error.runtimeType);
      return null;
    }
  }
}
