import 'package:dio/dio.dart';

/// Reintenta solo lecturas (GET/HEAD/OPTIONS) que no llegaron al servidor:
/// error de conexión o timeout al conectar (regla de la 1.10).
///
/// Nunca reintenta POST/PUT/PATCH/DELETE, ni timeouts de envío/recepción (el
/// servidor pudo procesarla), ni respuestas 4xx/5xx.
class RetryInterceptor extends Interceptor {
  static const retryCountKey = 'retryCount';
  static const _idempotentMethods = {'GET', 'HEAD', 'OPTIONS'};

  final Dio _dio;
  final int maxRetries;
  final Duration Function(int attempt) _delay;

  RetryInterceptor({
    required Dio dio,
    this.maxRetries = 3,
    Duration Function(int attempt)? delay,
  })  : _dio = dio,
        _delay = delay ?? _defaultDelay;

  static Duration _defaultDelay(int attempt) => Duration(seconds: attempt);

  /// Única regla de reintento de la app.
  static bool shouldRetry(DioException error) {
    final method = error.requestOptions.method.toUpperCase();
    if (!_idempotentMethods.contains(method)) return false;
    return error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.connectionError;
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    final attempt = (options.extra[retryCountKey] as int? ?? 0) + 1;
    if (!shouldRetry(err) || attempt > maxRetries) return handler.next(err);

    await Future<void>.delayed(_delay(attempt));
    options.extra[retryCountKey] = attempt;
    try {
      // Pasa otra vez por los interceptores: vuelve a leer el token y, si
      // falla de nuevo, este mismo interceptor decide el siguiente intento.
      handler.resolve(await _dio.fetch<dynamic>(options));
    } on DioException catch (error) {
      handler.next(error);
    }
  }
}
