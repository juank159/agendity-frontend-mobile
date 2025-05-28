// lib/core/config/utils/string_utils.dart

class StringUtils {
  static String getInitials(String fullName) {
    if (fullName.isEmpty) return '';

    final trimmedName = fullName.trim();
    if (trimmedName.isEmpty) return '';

    final parts = trimmedName.split(' ');
    if (parts.isEmpty) return '';

    if (parts.length == 1) {
      return parts[0].substring(0, 1).toUpperCase();
    }

    return parts[0].substring(0, 1).toUpperCase() +
        parts.last.substring(0, 1).toUpperCase();
  }

  static String formatPhoneNumber(String phone) {
    if (phone.isEmpty) return '';

    // Eliminar todos los caracteres que no sean dígitos
    final digitsOnly = phone.replaceAll(RegExp(r'[^\d+]'), '');

    // Si comienza con +, preservarlo
    final hasPlus = digitsOnly.startsWith('+');
    final digits = hasPlus ? digitsOnly.substring(1) : digitsOnly;

    if (digits.length <= 4) {
      return digitsOnly;
    } else if (digits.length <= 7) {
      return '${hasPlus ? '+' : ''}${digits.substring(0, digits.length - 4)}-${digits.substring(digits.length - 4)}';
    } else if (digits.length <= 10) {
      return '${hasPlus ? '+' : ''}${digits.substring(0, digits.length - 7)}-${digits.substring(digits.length - 7, digits.length - 4)}-${digits.substring(digits.length - 4)}';
    } else {
      // Para números internacionales
      return '${hasPlus ? '+' : ''}${digits.substring(0, digits.length - 10)}-${digits.substring(digits.length - 10, digits.length - 7)}-${digits.substring(digits.length - 7, digits.length - 4)}-${digits.substring(digits.length - 4)}';
    }
  }
}
