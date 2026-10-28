import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/features/auth/domain/failures/auth_failures.dart';
import 'package:login_signup/shared/widgets/app_dialogs.dart';
import 'package:login_signup/shared/widgets/app_snackbar.dart';

/// Mensajes de la UI de autenticación comunes a sus controllers. Se decide
/// por el **tipo** de failure (ARQUITECTURA §3), nunca comparando textos.
abstract final class AuthFeedback {
  static const invalidCredentialsMessage = 'Correo o contraseña incorrectos';
  static const tooManyRequestsMessage =
      'Hiciste demasiados intentos. Espera un minuto y vuelve a intentarlo.';
  static const accountNotFoundMessage =
      'No encontramos una cuenta con ese correo';
  static const sessionNotStartedMessage =
      'No se pudo iniciar la sesión. Inténtalo de nuevo.';

  /// Mensaje para el usuario de un fallo de auth.
  static String messageFor(Failure failure) => switch (failure) {
        InvalidCredentialsFailure() => invalidCredentialsMessage,
        TooManyRequestsFailure() => tooManyRequestsMessage,
        NotFoundFailure() => accountNotFoundMessage,
        _ => failure.message,
      };

  /// Avisa de un fallo. La cuenta sin acceso usa un diálogo con el motivo
  /// del backend (sin verificar, desactivada, dada de baja o sin negocio);
  /// los datos que el usuario puede corregir, una advertencia; el resto, un
  /// error. Cancelar el selector de Google no avisa de nada.
  static Future<void> show(Failure failure, {required String title}) async {
    switch (failure) {
      case GoogleSignInCancelledFailure():
        return;
      case AccountInactiveFailure():
        await AppDialogs.error(
          title: 'Tu cuenta no tiene acceso',
          message: failure.message,
        );
      case DuplicateEmailFailure():
      case DuplicatePhoneFailure():
        AppSnackbar.warning(failure.message, title: 'Dato ya registrado');
      case TooManyRequestsFailure():
        AppSnackbar.warning(tooManyRequestsMessage,
            title: 'Demasiados intentos');
      case ValidationFailure():
        AppSnackbar.warning(failure.message, title: 'Revisa los datos');
      default:
        AppSnackbar.error(messageFor(failure), title: title);
    }
  }
}
