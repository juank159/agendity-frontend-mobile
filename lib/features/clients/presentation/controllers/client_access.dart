import 'package:get/get.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/features/clients/domain/failures/client_failures.dart';
import 'package:login_signup/shared/controllers/session_controller.dart';
import 'package:login_signup/shared/widgets/app_dialogs.dart';
import 'package:login_signup/shared/widgets/app_snackbar.dart';

/// Reglas de la UI de clientes comunes a los controllers de la feature.
abstract final class ClientAccess {
  static const hasHistoryMessage =
      'Este cliente tiene citas o reseñas registradas, así que no se puede '
      'eliminar. Conserva su historial.';

  static const forbiddenMessage =
      'No tienes permiso para realizar esta acción con los clientes.';

  /// Owner y Employee crean y editan clientes; solo el Owner los borra
  /// (decisión del 2026-10-27; el backend lo aplica en la 2.32). Sin sesión
  /// registrada, no. Leído dentro de un `Obx` reacciona a la sesión.
  static bool canDelete() =>
      Get.isRegistered<SessionController>() &&
      Get.find<SessionController>().isOwner;

  /// Mensaje para el usuario de un fallo de clientes.
  static String messageFor(Failure failure) {
    if (failure is ClientHasHistoryFailure) return hasHistoryMessage;
    if (failure is ForbiddenFailure) return forbiddenMessage;
    return failure.message;
  }

  /// Avisa de un fallo: datos inválidos o repetidos como advertencia (el
  /// usuario puede corregirlos), el historial con un diálogo y el resto como
  /// error.
  static Future<void> show(Failure failure) async {
    if (failure is ClientHasHistoryFailure) {
      await AppDialogs.error(
        title: 'No se puede eliminar',
        message: hasHistoryMessage,
      );
    } else if (failure is DuplicateClientFailure) {
      AppSnackbar.warning(failure.message, title: 'Cliente repetido');
    } else if (failure is ValidationFailure) {
      AppSnackbar.warning(failure.message, title: 'Revisa los datos');
    } else {
      AppSnackbar.error(messageFor(failure));
    }
  }
}
