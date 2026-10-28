import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/routes/routes.dart';
import 'package:login_signup/shared/controllers/session_controller.dart';

/// Devuelve la sesión de la UI o `null` si aún no está registrada.
typedef SessionLookup = SessionController? Function();

SessionController? defaultSessionLookup() =>
    Get.isRegistered<SessionController>() ? Get.find<SessionController>() : null;

/// Protege las rutas que exigen sesión. Es **síncrono**: lee la sesión en
/// memoria, que el splash carga con `SessionController.restore()` antes de
/// navegar. Sin sesión vigente (o vencida) redirige al login.
class AuthMiddleware extends GetMiddleware {
  final SessionLookup _lookup;

  AuthMiddleware({SessionLookup? lookup, super.priority = 0})
      : _lookup = lookup ?? defaultSessionLookup;

  @override
  RouteSettings? redirect(String? route) {
    final session = _lookup();
    if (session != null && session.isLoggedIn) return null;
    return const RouteSettings(name: GetRoutes.login);
  }
}
