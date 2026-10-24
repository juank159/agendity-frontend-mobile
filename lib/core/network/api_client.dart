import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:login_signup/core/network/interceptors/auth_interceptor.dart';
import 'package:login_signup/core/network/interceptors/log_interceptor.dart';
import 'package:login_signup/core/network/interceptors/retry_interceptor.dart';
import 'package:login_signup/core/session/token_store.dart';

/// Tag del Dio nuevo en GetX (D-04): `Get.find<Dio>(tag: apiClientTag)`.
/// Convive con el Dio sin tag de `ApiConfig` hasta terminar la Fase 4.
const apiClientTag = 'api';

/// Único sitio que crea el `Dio` de la app (ARQUITECTURA.md §2.2).
///
/// - `validateStatus` por defecto de Dio: cualquier respuesta que no sea 2xx
///   es un `DioException` que `safeCall` traduce con el `ErrorMapper`.
/// - Interceptores: token y 401 → [onSessionExpired]; log seguro (solo debug);
///   reintento de lecturas sin conexión.
/// - Timeouts largos (subidas, lotes) se piden por petición con `Options`.
Dio buildApiClient({
  required String baseUrl,
  required TokenStore tokenStore,
  SessionExpiredCallback? onSessionExpired,
  HttpClientAdapter? httpClientAdapter,
  Duration Function(int attempt)? retryDelay,
  bool enableLogs = kDebugMode,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
      headers: const {'Accept': 'application/json'},
    ),
  );
  if (httpClientAdapter != null) dio.httpClientAdapter = httpClientAdapter;

  dio.interceptors.addAll([
    AuthInterceptor(
      tokenStore: tokenStore,
      onSessionExpired: onSessionExpired,
    ),
    SafeLogInterceptor(enabled: enableLogs),
    RetryInterceptor(dio: dio, delay: retryDelay),
  ]);
  return dio;
}
