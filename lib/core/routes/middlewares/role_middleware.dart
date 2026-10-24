import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/routes/middlewares/auth_middleware.dart';
import 'package:login_signup/core/routes/routes.dart';

/// Rutas solo para el Owner (el backend responde 403 al Employee).
/// Va **después** de [AuthMiddleware] (prioridad mayor): sin sesión, ya
/// redirigió al login. Un usuario sin rol Owner vuelve a la home.
class RoleMiddleware extends GetMiddleware {
  final SessionLookup _lookup;

  RoleMiddleware({SessionLookup? lookup, super.priority = 1})
      : _lookup = lookup ?? defaultSessionLookup;

  /// Middlewares de una ruta solo para el Owner.
  static List<GetMiddleware> ownerOnly() =>
      [AuthMiddleware(), RoleMiddleware()];

  @override
  RouteSettings? redirect(String? route) {
    final session = _lookup();
    if (session == null || !session.isLoggedIn) {
      return const RouteSettings(name: GetRoutes.login);
    }
    if (session.isOwner) return null;
    return const RouteSettings(name: GetRoutes.home);
  }
}
