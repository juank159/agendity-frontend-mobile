import 'package:login_signup/features/clients/domain/entities/client_entity.dart';

/// Reglas de los datos de un cliente que la app comprueba antes de enviarlos
/// (las del backend, `CreateClientDto`, más el mínimo de dígitos de la app).
abstract final class ClientRules {
  /// La app pide un teléfono de al menos 10 dígitos (celular colombiano).
  static const minPhoneDigits = 10;

  static const nameRequired = 'El nombre es obligatorio';
  static const phoneTooShort =
      'El teléfono debe tener al menos $minPhoneDigits dígitos';
  static const invalidEmail = 'El email no es válido';

  static final _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  /// Solo dígitos, con el `+` inicial si lo había (`"+57 300-123 4567"` →
  /// `"+573001234567"`). Es la forma en que se guarda: el teléfono es único
  /// por negocio, así que siempre se envía igual.
  static String normalizePhone(String phone) {
    final trimmed = phone.trim();
    final digits = trimmed.replaceAll(RegExp(r'\D'), '');
    return trimmed.startsWith('+') && digits.isNotEmpty ? '+$digits' : digits;
  }

  static int phoneDigits(String phone) =>
      phone.replaceAll(RegExp(r'\D'), '').length;

  static bool isValidEmail(String email) => _email.hasMatch(email.trim());

  /// Textos sin espacios sobrantes, teléfono normalizado y opcionales vacíos
  /// como `null` (un email vacío = sin email).
  static ClientEntity normalize(ClientEntity client) => ClientEntity(
        id: client.id,
        name: client.name.trim(),
        lastname: client.lastname.trim(),
        email: _optional(client.email),
        phone: normalizePhone(client.phone),
        image: _optional(client.image),
        address: _optional(client.address),
        isFromDevice: client.isFromDevice,
        deviceContactId: _optional(client.deviceContactId),
        lastVisit: client.lastVisit,
        isActive: client.isActive,
        createdAt: client.createdAt,
        updatedAt: client.updatedAt,
        notes: _optional(client.notes),
        birthday: client.birthday,
        showNotes: client.showNotes,
      );

  /// Problemas de un cliente ya normalizado; vacío si es válido.
  static List<String> check(ClientEntity client) => [
        if (client.name.isEmpty) nameRequired,
        if (phoneDigits(client.phone) < minPhoneDigits) phoneTooShort,
        if (client.email != null && !isValidEmail(client.email!)) invalidEmail,
      ];

  static String? _optional(String? value) {
    final text = value?.trim();
    return text == null || text.isEmpty ? null : text;
  }
}
