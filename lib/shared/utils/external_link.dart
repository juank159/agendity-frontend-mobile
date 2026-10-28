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

/// `tel:` para llamar a [phone] (dígitos, con el `+` si lo trae). `null` si
/// no hay dígitos.
Uri? phoneCallUri(String phone) {
  final trimmed = phone.trim();
  final digits = trimmed.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return null;
  return Uri(scheme: 'tel', path: trimmed.startsWith('+') ? '+$digits' : digits);
}

/// Número para `wa.me`: la MISMA regla que el backend (`toWhatsappPhone`,
/// `backend/src/whatsapp/whatsapp-phone.ts`): con `+` ya trae indicativo;
/// si empieza por el indicativo y es más largo que un número local, se
/// respeta; 10 dígitos (móvil colombiano) → se antepone [countryCode].
String toWhatsappPhone(String phone, {String countryCode = '57'}) {
  final raw = phone.trim();
  final digits = raw.replaceAll(RegExp(r'\D'), '');
  if (raw.startsWith('+')) return digits;
  if (digits.startsWith(countryCode) && digits.length > 10) return digits;
  if (digits.length == 10) return '$countryCode$digits';
  return digits;
}

/// Chat de WhatsApp con [phone] (`https://wa.me/<número>`, con [text] si se
/// da). `null` si no hay dígitos.
Uri? whatsappUri(String phone, {String? text}) {
  final number = toWhatsappPhone(phone);
  if (number.isEmpty) return null;
  return Uri.https('wa.me', '/$number',
      text == null || text.isEmpty ? null : {'text': text});
}
