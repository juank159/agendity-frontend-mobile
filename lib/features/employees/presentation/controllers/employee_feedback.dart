import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/features/employees/domain/failures/employee_failures.dart';
import 'package:login_signup/shared/widgets/app_dialogs.dart';
import 'package:login_signup/shared/widgets/app_snackbar.dart';

/// Mensajes de la UI de profesionales comunes a los controllers de la
/// feature (la gestión de profesionales es solo del Owner: ruta `ownerOnly`).
abstract final class EmployeeFeedback {
  static const forbiddenMessage =
      'Solo el propietario del negocio puede gestionar profesionales.';
  static const notFoundMessage =
      'El profesional ya no existe o fue eliminado. Actualiza la lista.';

  /// Mensaje para el usuario de un fallo de profesionales.
  static String messageFor(Failure failure) {
    if (failure is ForbiddenFailure) return forbiddenMessage;
    if (failure is NotFoundFailure) return notFoundMessage;
    return failure.message;
  }

  /// Avisa de un fallo al guardar o al cambiar el estado: datos inválidos o
  /// repetidos como advertencia (el usuario puede corregirlos), el email sin
  /// verificar con un diálogo que explica el motivo y el resto como error.
  static Future<void> show(Failure failure) async {
    switch (failure) {
      case EmployeeEmailNotVerifiedFailure():
        await AppDialogs.error(
          title: 'Falta verificar el email',
          message: failure.message,
        );
      case DuplicateEmailFailure():
        AppSnackbar.warning(failure.message, title: 'Email repetido');
      case DuplicatePhoneFailure():
        AppSnackbar.warning(failure.message, title: 'Teléfono repetido');
      case ValidationFailure():
        AppSnackbar.warning(failure.message, title: 'Revisa los datos');
      default:
        AppSnackbar.error(messageFor(failure));
    }
  }
}
