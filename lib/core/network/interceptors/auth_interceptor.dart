import 'dart:async';

import 'package:dio/dio.dart';
import 'package:login_signup/core/session/token_store.dart';

/// Se llama cuando el backend responde 401 a una petición que llevaba token.
/// Lo provee la capa de sesión (3.02); core nunca navega.
typedef SessionExpiredCallback = FutureOr<void> Function();

/// Pone `Authorization: Bearer <token>` en cada petición y avisa de la sesión
/// expirada ante un 401.
///
/// - Rutas públicas (login, registro, recuperar contraseña…): marcar la
///   petición con `Options(extra: {AuthInterceptor.publicKey: true})`; no se
///   envía token y su 401 (p. ej. "Credenciales inválidas") no cierra sesión.
/// - El aviso se da una sola vez por token: varias peticiones que fallan a la
///   vez con el mismo token vencido no disparan varios cierres de sesión.
class AuthInterceptor extends Interceptor {
  static const publicKey = 'public';
  static const _tokenKey = 'authToken';

  final TokenStore _tokenStore;
  final SessionExpiredCallback? _onSessionExpired;
  String? _expiredToken;

  AuthInterceptor({
    required TokenStore tokenStore,
    SessionExpiredCallback? onSessionExpired,
  })  : _tokenStore = tokenStore,
        _onSessionExpired = onSessionExpired;

  static bool isPublic(RequestOptions options) =>
      options.extra[publicKey] == true;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (isPublic(options)) return handler.next(options);

    final String? token;
    try {
      token = await _tokenStore.readToken();
    } catch (error, stackTrace) {
      return handler.reject(
        DioException(
          requestOptions: options,
          error: error,
          stackTrace: stackTrace,
          message: 'No se pudo leer el token de sesión',
        ),
      );
    }

    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
      options.extra[_tokenKey] = token;
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    final sentToken = options.extra[_tokenKey];
    if (err.response?.statusCode == 401 &&
        !isPublic(options) &&
        sentToken is String &&
        sentToken != _expiredToken) {
      _expiredToken = sentToken;
      try {
        await _onSessionExpired?.call();
      } catch (_) {
        // El aviso no debe cambiar el error que recibe quien hizo la petición.
      }
    }
    handler.next(err);
  }
}
