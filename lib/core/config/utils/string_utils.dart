class StringUtils {
  static String getInitials(String name) {
    if (name.isEmpty) return '';
    final nameParts = name.split(' ');
    return nameParts[0][0].toUpperCase();
  }

  static String formatPhoneNumber(String phone) {
    if (phone.isEmpty) return '';
    final cleanNumber = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanNumber.length == 10) {
      return '${cleanNumber.substring(0, 3)} ${cleanNumber.substring(3, 6)} ${cleanNumber.substring(6)}';
    }
    return phone;
  }
}
