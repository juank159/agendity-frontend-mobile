import 'package:flutter/widgets.dart';
import 'package:login_signup/core/utils/app_logger.dart';
import 'package:share_plus/share_plus.dart';

/// Comparte [text] con el menú nativo del teléfono. `false` si no se pudo
/// abrir (cerrar el menú sin elegir no es un error).
typedef TextSharer = Future<bool> Function(String text,
    {String? subject, Rect? origin});

/// **Única** puerta de presentation a `share_plus` (como
/// `external_link.dart` con `url_launcher`). Los controllers la reciben
/// inyectada para probarlos sin plataforma.
Future<bool> shareText(String text, {String? subject, Rect? origin}) async {
  try {
    final result = await SharePlus.instance.share(ShareParams(
      text: text,
      subject: subject,
      // iPad y macOS anclan el menú a un punto de la pantalla.
      sharePositionOrigin: origin,
    ));
    return result.status != ShareResultStatus.unavailable;
  } catch (e) {
    AppLogger.error('No se pudo abrir el menú de compartir', e);
    return false;
  }
}
