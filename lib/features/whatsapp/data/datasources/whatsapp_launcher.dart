// lib/features/whatsapp/data/datasources/whatsapp_launcher.dart
import 'package:url_launcher/url_launcher.dart';

class WhatsappLauncher {
  /// Abre WhatsApp con un mensaje predefinido para el número especificado
  static Future<bool> openWhatsAppChat(
      String phoneNumber, String message) async {
    // Formatear el número (eliminar caracteres no numéricos y asegurar código de país)
    final formattedPhone = _formatPhoneNumber(phoneNumber);

    // Codificar el mensaje para URL
    final encodedMessage = Uri.encodeComponent(message);

    // Crear URL de WhatsApp
    final whatsappUrl =
        "whatsapp://send?phone=$formattedPhone&text=$encodedMessage";

    // Intentar abrir WhatsApp
    final uri = Uri.parse(whatsappUrl);
    if (await canLaunchUrl(uri)) {
      return launchUrl(uri);
    } else {
      // Fallback a WhatsApp Web si la app no está instalada
      final webWhatsappUrl =
          "https://wa.me/$formattedPhone?text=$encodedMessage";
      final webUri = Uri.parse(webWhatsappUrl);
      return launchUrl(webUri, mode: LaunchMode.externalApplication);
    }
  }

  /// Formatea el número de teléfono para WhatsApp
  static String _formatPhoneNumber(String phone) {
    // Eliminar caracteres no numéricos
    String cleaned = phone.replaceAll(RegExp(r'[^\d]'), '');

    // Asegurarse de que tenga código de país (asumiendo Colombia 57 por defecto)
    if (cleaned.length == 10) {
      cleaned = '57$cleaned';
    } else if (cleaned.startsWith('57') && cleaned.length >= 12) {
      // Ya tiene código de país, no hacer cambios
    }

    return cleaned;
  }
}
