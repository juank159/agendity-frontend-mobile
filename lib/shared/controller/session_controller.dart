import 'dart:async';

import 'package:get/get.dart';
import 'package:login_signup/core/session/session_repository.dart';
import 'package:login_signup/core/session/session_service.dart';

/// Sesión en memoria para la UI (usuario, roles, tenant), sobre [SessionService].
///
/// - Es el **único** sitio de presentation que conoce la sesión: nadie más
///   decodifica el JWT ni lee `'token'`.
/// - Los middlewares de rutas la leen de forma síncrona ([isLoggedIn],
///   [isOwner]); por eso el splash llama a [restore] antes de navegar.
/// - Se registra una sola vez (`core/di/modules/user_module.dart`).
class SessionController extends GetxController {
  final SessionService _service;
  final DateTime Function() _now;

  /// Sesión actual o `null`. Reactiva para la UI.
  final Rxn<Session> session = Rxn<Session>();

  SessionController(this._service, {DateTime Function()? clock})
      : _now = clock ?? DateTime.now;

  // --- Lecturas síncronas -------------------------------------------------

  /// Hay sesión y no ha vencido.
  bool get isLoggedIn {
    final current = session.value;
    return current != null && !current.isExpiredAt(_now());
  }

  bool get isOwner => session.value?.isOwner ?? false;

  /// Employee que no es Owner.
  bool get isOnlyEmployee => session.value?.isOnlyEmployee ?? false;

  String get userId => session.value?.userId ?? '';
  String? get tenantId => session.value?.tenantId;
  String? get name => session.value?.name;
  String? get email => session.value?.email;
  List<String> get roles => session.value?.roles ?? const [];

  // --- Ciclo de vida ------------------------------------------------------

  /// Auto-login: carga la sesión guardada si es válida (borra la vencida).
  Future<Session?> restore() async {
    session.value = await _service.restore();
    return session.value;
  }

  /// Tras un login cuyo token ya guardó la capa de datos (auth hoy guarda el
  /// token en el repositorio). Lee la sesión vigente.
  Future<Session?> reload() async {
    session.value = await _service.current();
    return session.value;
  }

  /// Inicia sesión con un token recibido en presentation.
  Future<Session> start(String token) async {
    final started = await _service.start(token);
    session.value = started;
    return started;
  }

  /// Cierra la sesión (borra el token) y limpia el estado.
  Future<void> end() async {
    await _service.end();
    session.value = null;
  }

  /// El token ya lo borró `SessionService.handleSessionExpired`; solo se
  /// limpia el estado en memoria.
  void clear() => session.value = null;
}
