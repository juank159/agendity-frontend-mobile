import 'package:login_signup/features/auth/domain/failures/auth_failures.dart';

/// Reglas que los use cases de auth comprueban antes de llamar al backend.
/// Sustituye a las dos `ValidationFailure` locales que sombreaban la de core.
abstract final class AuthRules {
  static const invalidEmail = 'Email inválido';
  static const missingCode = 'Ingresa el código que te enviamos';

  static final _email = RegExp(r'^[\w\-.+]+@([\w-]+\.)+[\w-]{2,}$');

  static bool isValidEmail(String email) => _email.hasMatch(email.trim());

  /// `null` si el email es válido.
  static InvalidAuthDataFailure? checkEmail(String email) => isValidEmail(email)
      ? null
      : const InvalidAuthDataFailure(message: invalidEmail);
}
