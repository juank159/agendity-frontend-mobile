import 'package:url_launcher/url_launcher.dart';

/// Abre [uri] fuera de la app (WhatsApp `wa.me`, `tel:`, web). `false` si el
/// sistema no pudo abrirlo.
///
/// Es la única puerta a `url_launcher` desde presentation; los controllers
/// la reciben inyectada para poder probarlos.
typedef ExternalLinkOpener = Future<bool> Function(Uri uri);

Future<bool> openExternalLink(Uri uri) async {
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}
