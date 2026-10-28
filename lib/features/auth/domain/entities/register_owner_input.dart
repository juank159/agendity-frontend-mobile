/// Datos del alta de un negocio (`POST /auth/register/owner`).
class RegisterOwnerInput {
  final String name;
  final String lastname;
  final String email;
  final String phone;
  final String password;

  const RegisterOwnerInput({
    required this.name,
    required this.lastname,
    required this.email,
    required this.phone,
    required this.password,
  });

  /// Sin espacios sobrantes (la contraseña se envía tal cual).
  RegisterOwnerInput normalized() => RegisterOwnerInput(
        name: name.trim(),
        lastname: lastname.trim(),
        email: email.trim(),
        phone: phone.trim(),
        password: password,
      );
}
