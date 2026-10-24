import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Log de red seguro: solo en debug, solo método, URL, estado y `code`.
/// Nunca headers (llevan `Authorization`) ni cuerpos (contraseñas, tokens).
class SafeLogInterceptor extends Interceptor {
  final bool enabled;
  final void Function(String line) _log;

  SafeLogInterceptor({this.enabled = kDebugMode, void Function(String)? log})
      : _log = log ?? ((line) => debugPrint(line));

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (enabled) _log('[api] → ${options.method} ${_path(options)}');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (enabled) {
      _log('[api] ← ${response.statusCode} '
          '${response.requestOptions.method} ${_path(response.requestOptions)}');
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (enabled) {
      final data = err.response?.data;
      final code = data is Map ? data['code'] : null;
      _log('[api] ✕ ${err.response?.statusCode ?? err.type.name} '
          '${err.requestOptions.method} ${_path(err.requestOptions)}'
          '${code != null ? ' code=$code' : ''}');
    }
    handler.next(err);
  }

  /// Sin query string: puede llevar emails, teléfonos o códigos.
  static String _path(RequestOptions options) => options.uri.path;
}
