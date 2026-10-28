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

  const RegisterOwnerInput({
    required this.name,
    required this.lastname,
    required this.email,
    required this.phone,
    required this.password,
    this.timeZone,
  });

  /// Sin espacios sobrantes (la contraseña se envía tal cual).
  RegisterOwnerInput normalized() => RegisterOwnerInput(
        name: name.trim(),
        lastname: lastname.trim(),
        email: email.trim(),
        phone: phone.trim(),
        password: password,
        timeZone: timeZone?.trim().isEmpty ?? true ? null : timeZone!.trim(),
      );

  RegisterOwnerInput withTimeZone(String? zone) => RegisterOwnerInput(
        name: name,
        lastname: lastname,
        email: email,
        phone: phone,
        password: password,
        timeZone: zone,
      );
}
