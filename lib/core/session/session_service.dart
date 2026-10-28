import 'dart:async';

import 'package:login_signup/core/session/session_repository.dart';
import 'package:login_signup/core/session/time_zone_store.dart';
import 'package:login_signup/core/session/token_store.dart';
import 'package:login_signup/core/utils/app_logger.dart';
import 'package:login_signup/core/utils/business_time_zone.dart';

/// Lee del backend la zona IANA del negocio de la sesión (`GET /auth/me`).
typedef TimeZoneLoader = Future<String?> Function();

/// Punto de entrada de la sesión para presentation (sin GetX: lo registra la DI).
///
/// - `restore()`: auto-login del splash.
/// - `start(token)`: tras un login correcto.
/// - `end()`: logout (solo el token y la zona; el resto de datos locales lo
///   limpia quien cierra sesión).
/// - `onSessionExpired`: lo asigna presentation (3.02 FP) para navegar al
///   login. Lo dispara el `AuthInterceptor` del Dio `'api'` ante un 401.
///
/// **Zona del negocio (D-15):** `restore()` y `start()` la cargan con
/// [loadTimeZone] (la conecta auth en su DI) y la fijan en
/// `BusinessTimeZone`, que usan `DateCodec` y el "ahora" del negocio. Si no
/// se puede leer (sin red), se usa la última guardada; si nunca se leyó, la
/// por defecto. Cambiarla en la configuración llama a [applyTimeZone].
class SessionService {
  final TokenStore _tokenStore;
  final SessionRepository _repository;
  final TimeZoneStore? _timeZoneStore;

  /// Lo asigna presentation. Se llama después de borrar el token vencido.
  FutureOr<void> Function()? onSessionExpired;

  /// Lo asigna la DI de auth (lee `GET /auth/me` con el token ya guardado).
  TimeZoneLoader? loadTimeZone;

  String? _timeZone;

  SessionService({
    required TokenStore tokenStore,
    required SessionRepository repository,
    TimeZoneStore? timeZoneStore,
    this.loadTimeZone,
  })  : _tokenStore = tokenStore,
        _repository = repository,
        _timeZoneStore = timeZoneStore;

  /// Zona IANA del negocio de la sesión, o `null` si aún no se conoce.
  String? get timeZone => _timeZone;

  /// Sesión vigente o `null`. Si el token guardado está vencido o malformado,
  /// lo borra. Carga la zona del negocio.
  Future<Session?> restore() async {
    final session = await _repository.activeSession();
    if (session == null) {
      if (await _tokenStore.readToken() != null) {
        await _tokenStore.clearToken();
      }
      await _forgetTimeZone();
      return null;
    }
    await _refreshTimeZone();
    // `/auth/me` pudo responder 401 (cuenta desactivada): entonces
    // `handleSessionExpired` ya borró el token y no hay sesión que devolver.
    if (await _tokenStore.readToken() != session.token) return null;
    return session.withTimeZone(_timeZone);
  }

  /// Sesión actual sin efectos (vigente o `null`), con la zona conocida.
  Future<Session?> current() async =>
      (await _repository.activeSession())?.withTimeZone(_timeZone);

  /// Guarda el token del login y carga la zona del negocio. Lanza
  /// `FormatException` si no es un JWT válido (y no guarda nada). Si la zona
  /// no se puede leer, el login sigue (con la última conocida o la por
  /// defecto).
  Future<Session> start(String token) async {
    final session = SessionRepository.decode(token.trim());
    if (session == null) {
      throw const FormatException('El token de sesión no es válido');
    }
    await _tokenStore.saveToken(token);
    await _refreshTimeZone();
    return session.withTimeZone(_timeZone);
  }

  Future<void> end() async {
    await _tokenStore.clearToken();
    await _forgetTimeZone();
  }

  /// La zona del negocio cambió (respuesta de `GET`/`PATCH /settings`).
  /// Una zona desconocida se ignora.
  Future<void> applyTimeZone(String timeZone) async {
    final canonical = BusinessTimeZone.canonicalName(timeZone);
    if (canonical == null) {
      AppLogger.error('Zona del negocio desconocida', timeZone);
      return;
    }
    _timeZone = canonical;
    BusinessTimeZone.use(canonical);
    await _timeZoneStore?.save(canonical);
  }

  /// Conectado al `AuthInterceptor` en la DI: [expiredToken] es el token que
  /// recibió el 401. Si sigue siendo el guardado, lo borra y avisa a
  /// presentation; si ya hay otro (se volvió a iniciar sesión), no hace nada.
  /// Core nunca navega.
  Future<void> handleSessionExpired(String expiredToken) async {
    if (await _tokenStore.readToken() != expiredToken) return;
    await end();
    await onSessionExpired?.call();
  }

  Future<void> _refreshTimeZone() async {
    String? loaded;
    try {
      loaded = await loadTimeZone?.call();
    } catch (error) {
      AppLogger.error('No se pudo leer la zona del negocio', error.runtimeType);
    }
    if (loaded != null && BusinessTimeZone.isValid(loaded)) {
      return applyTimeZone(loaded);
    }
    final stored = await _timeZoneStore?.read();
    if (BusinessTimeZone.use(stored)) {
      _timeZone = BusinessTimeZone.current;
    }
  }

  Future<void> _forgetTimeZone() async {
    _timeZone = null;
    BusinessTimeZone.reset();
    await _timeZoneStore?.clear();
  }
}
