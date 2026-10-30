/// Datos del alta de un negocio (`POST /auth/register/owner`).
class RegisterOwnerInput {
  final String name;
  final String lastname;
  final String email;
  final String phone;
  final String password;

  /// Zona IANA del negocio (D-15). Si falta, el repositorio envía la del
  /// dispositivo; si tampoco hay, el backend usa la suya por defecto.
  final String? timeZone;

  /// Nombre del negocio (8.00, opcional): de él sale el slug del link
  /// público. Vacío = sin nombre.
  final String? businessName;

  const RegisterOwnerInput({
    required this.name,
    required this.lastname,
    required this.email,
    required this.phone,
    required this.password,
    this.timeZone,
    this.businessName,
  });

  /// Sin espacios sobrantes (la contraseña se envía tal cual).
  RegisterOwnerInput normalized() => RegisterOwnerInput(
        name: name.trim(),
        lastname: lastname.trim(),
        email: email.trim(),
        phone: phone.trim(),
        password: password,
        timeZone: _blankToNull(timeZone),
        businessName: _blankToNull(businessName),
      );

  static String? _blankToNull(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  RegisterOwnerInput withTimeZone(String? zone) => RegisterOwnerInput(
        name: name,
        lastname: lastname,
        email: email,
        phone: phone,
        password: password,
        timeZone: zone,
        businessName: businessName,
      );
}
