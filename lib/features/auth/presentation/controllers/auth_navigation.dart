import 'package:get/get.dart';
import 'package:login_signup/core/routes/routes.dart';
import 'package:login_signup/shared/controller/session_controller.dart';
import 'package:login_signup/shared/widgets/app_snackbar.dart';
import 'auth_feedback.dart';

/// Entrada a la app tras iniciar la sesión (login, Google o registro).
abstract final class AuthNavigation {
  /// Clave del email en los `arguments` de `/verify-email` y
  /// `/reset-password`.
  static const emailKey = 'email';

  /// Email recibido por `arguments` (vacío si falta).
  static String emailArgument() {
    final args = Get.arguments;
    final value = args is Map ? args[emailKey] : null;
    return value is String ? value.trim() : '';
  }

  /// Login, registro y Google ya guardaron el JWT (`SessionService.start`):
  /// se carga la sesión de la UI y, solo si hay una vigente, se va a la home
  /// (el `AuthMiddleware` la exige). Devuelve `false` si no hay sesión
  /// (avisa del error salvo con [reportMissing] en `false`).
  static Future<bool> enterHome({
    SessionController? session,
    bool reportMissing = true,
  }) async {
    final current =
        await (session ?? Get.find<SessionController>()).reload();
    if (current == null) {
      if (!reportMissing) return false;
      AppSnackbar.error(AuthFeedback.sessionNotStartedMessage,
          title: 'No se pudo iniciar sesión');
      return false;
    }
    Get.offAllNamed(GetRoutes.home);
    return true;
  }
}
