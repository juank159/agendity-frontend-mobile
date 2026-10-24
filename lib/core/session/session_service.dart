import 'dart:async';

import 'package:login_signup/core/session/session_repository.dart';
import 'package:login_signup/core/session/token_store.dart';

/// Punto de entrada de la sesión para presentation (sin GetX: lo registra la DI).
///
/// - `restore()`: auto-login del splash.
/// - `start(token)`: tras un login correcto.
/// - `end()`: logout (solo el token; el resto de datos locales lo limpia quien
///   cierra sesión).
/// - `onSessionExpired`: lo asigna presentation (3.02 FP) para navegar al
///   login. Lo dispara el `AuthInterceptor` del Dio `'api'` ante un 401.
class SessionService {
  final TokenStore _tokenStore;
  final SessionRepository _repository;

  /// Lo asigna presentation. Se llama después de borrar el token vencido.
  FutureOr<void> Function()? onSessionExpired;

  SessionService({
    required TokenStore tokenStore,
    required SessionRepository repository,
  })  : _tokenStore = tokenStore,
        _repository = repository;

  /// Sesión vigente o `null`. Si el token guardado está vencido o malformado,
  /// lo borra.
  Future<Session?> restore() async {
    final session = await _repository.activeSession();
    if (session == null && await _tokenStore.readToken() != null) {
      await _tokenStore.clearToken();
    }
    return session;
  }

  /// Sesión actual sin efectos (vigente o `null`).
  Future<Session?> current() => _repository.activeSession();

  /// Guarda el token del login. Lanza `FormatException` si no es un JWT válido
  /// (y no guarda nada).
  Future<Session> start(String token) async {
    final session = SessionRepository.decode(token.trim());
    if (session == null) {
      throw const FormatException('El token de sesión no es válido');
    }
    await _tokenStore.saveToken(token);
    return session;
  }

  Future<void> end() => _tokenStore.clearToken();

  /// Conectado al `AuthInterceptor` en la DI: [expiredToken] es el token que
  /// recibió el 401. Si sigue siendo el guardado, lo borra y avisa a
  /// presentation; si ya hay otro (se volvió a iniciar sesión), no hace nada.
  /// Core nunca navega.
  Future<void> handleSessionExpired(String expiredToken) async {
    if (await _tokenStore.readToken() != expiredToken) return;
    await end();
    await onSessionExpired?.call();
  }
}
