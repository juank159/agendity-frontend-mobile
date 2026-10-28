import 'package:login_signup/core/errors/failures.dart';

/// Email o contraseña incorrectos: `POST /auth/login` → 401 `UNAUTHORIZED`
/// ("Credenciales inválidas"). La ruta es pública: no cierra ninguna sesión.
class InvalidCredentialsFailure extends UnauthorizedFailure {
  static const defaultMessage = 'Credenciales inválidas';

  const InvalidCredentialsFailure({
    String? message,
    super.code,
    super.statusCode,
    super.details,
  }) : super(message: message ?? defaultMessage);
}

/// Login (email o Google) correcto de una cuenta sin acceso: sin verificar,
/// desactivada, dada de baja o empleado sin negocio (403 `ACCOUNT_INACTIVE`,
/// 2.12). El motivo va en [message].
class AccountInactiveFailure extends ForbiddenFailure {
  static const defaultMessage = 'Tu cuenta no tiene acceso en este momento';

  const AccountInactiveFailure({
    String? message,
    super.statusCode,
    super.details,
  }) : super(
          message: message ?? defaultMessage,
          code: ApiErrorCode.accountInactive,
        );
}

/// El backend rechazó el login con Google (401: token de Google inválido, sin
/// email verificado o login con Google no disponible). No se inicia sesión.
class GoogleSignInRejectedFailure extends UnauthorizedFailure {
  static const defaultMessage = 'No se pudo iniciar sesión con Google';

  const GoogleSignInRejectedFailure({
    String? message,
    super.code,
    super.statusCode,
    super.details,
  }) : super(message: message ?? defaultMessage);
}

/// El usuario cerró el selector de cuentas de Google.
class GoogleSignInCancelledFailure extends CancelledFailure {
  static const defaultMessage = 'Inicio de sesión con Google cancelado';

  const GoogleSignInCancelledFailure() : super(message: defaultMessage);
}

/// Datos fuera de las reglas (`AuthRules`). La producen los use cases antes
/// de llamar al backend.
class InvalidAuthDataFailure extends ValidationFailure {
  const InvalidAuthDataFailure({super.message});
}
