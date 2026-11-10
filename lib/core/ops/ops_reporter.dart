// Baudity Ops Reporter (Flutter) — copia este archivo en `lib/core/ops/`.
// Solo depende de Dio (ya está en todas las apps). Funciona en móvil,
// escritorio y web. Nunca lanza excepciones: si no hay internet, guarda los
// errores en memoria y los reintenta luego.
//
// Uso en main():
//   OpsReporter.init(
//     url: const String.fromEnvironment('OPS_URL'),   // o dotenv.env['OPS_URL']
//     key: const String.fromEnvironment('OPS_KEY'),
//     environment: kReleaseMode ? 'production' : 'development',
//     release: '1.4.2+30',
//     tenantId: () => authController.organizationId,
//   );
//   OpsReporter.installGlobalHandlers();
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

typedef OpsValueGetter = String? Function();
typedef OpsIgnore = bool Function(Object error);

class OpsReporter {
  OpsReporter._();

  static Dio? _dio;
  static String _environment = 'development';
  static String? _release;
  static OpsValueGetter? _tenantId;
  static OpsValueGetter? _userId;
  static OpsValueGetter? _route;
  static OpsIgnore? _ignore;
  static final List<Map<String, dynamic>> _pending = [];
  static final Map<String, DateTime> _lastSent = {};
  static Timer? _retryTimer;
  static int _sentThisMinute = 0;
  static DateTime _windowStart = DateTime.now();

  static const _maxPending = 30;
  static const _maxPerMinute = 30;

  static bool get enabled => _dio != null;

  /// Configura el reporter. Si `url` o `key` están vacíos queda desactivado.
  static void init({
    required String url,
    required String key,
    required String environment,
    String? release,
    OpsValueGetter? tenantId,
    OpsValueGetter? userId,
    OpsValueGetter? currentRoute,
    OpsIgnore? ignore,
  }) {
    if (url.isEmpty || key.isEmpty) return;
    _dio = Dio(BaseOptions(
      baseUrl: url.endsWith('/') ? url.substring(0, url.length - 1) : url,
      connectTimeout: const Duration(seconds: 5),
      sendTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'x-ops-key': key, 'content-type': 'application/json'},
    ));
    _environment = environment;
    _release = release;
    _tenantId = tenantId;
    _userId = userId;
    _route = currentRoute;
    _ignore = ignore;
    _retryTimer ??= Timer.periodic(const Duration(minutes: 1), (_) => _flush());
  }

  /// Engancha FlutterError.onError y PlatformDispatcher.onError, respetando
  /// los manejadores que la app ya tenga (se llaman primero). Para filtrar
  /// ruido de FlutterError usa `ignore` en init(), o llama a capture() tú
  /// mismo dentro de tu manejador en vez de usar este método.
  static void installGlobalHandlers() {
    final previousFlutter = FlutterError.onError;
    FlutterError.onError = (details) {
      previousFlutter?.call(details);
      if (details.silent) return;
      capture(details.exception, details.stack,
          context: {'library': details.library, 'info': details.context?.toDescription()});
    };
    final previousPlatform = PlatformDispatcher.instance.onError;
    PlatformDispatcher.instance.onError = (error, stack) {
      // Si el manejador previo devuelve true, la app lo silenció a propósito
      // (ruido conocido): no se reporta.
      final handled = previousPlatform?.call(error, stack) ?? false;
      if (!handled) capture(error, stack);
      return handled;
    };
  }

  /// Reporta un error manualmente (por ejemplo en un catch).
  static void capture(
    Object error,
    StackTrace? stack, {
    String level = 'error',
    String? route,
    Map<String, dynamic>? context,
    String? errorType,
    String? fingerprint,
  }) {
    try {
      if (_dio == null) return;
      if (_isNoise(error) || (_ignore?.call(error) ?? false)) return;
      final message = _messageOf(error);
      final key = fingerprint ??
          '${error.runtimeType}|${message.length > 200 ? message.substring(0, 200) : message}';
      if (!_allow(key)) return;
      _send({
        'level': level,
        'source': kIsWeb ? 'web' : 'app',
        'environment': _environment,
        'errorType': errorType ?? error.runtimeType.toString(),
        if (fingerprint != null) 'fingerprint': fingerprint,
        'message': message.length > 2000 ? message.substring(0, 2000) : message,
        if (stack != null) 'stack': _trim(stack.toString(), 20000),
        if ((route ?? _safe(_route)) != null) 'route': route ?? _safe(_route),
        if (_release != null) 'release': _release,
        if (_safe(_tenantId) != null) 'tenantId': _safe(_tenantId),
        if (_safe(_userId) != null) 'userId': _safe(_userId),
        if (context != null) 'context': context,
        'device': _device(),
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (_) {/* nunca romper la app */}
  }

  /// Envía un reporte de diagnóstico completo. Devuelve true si llegó.
  static Future<bool> sendDiagnostic({
    required String report,
    int? healthScore,
    List<String>? issues,
    String? tenantName,
    String? userNote,
  }) async {
    if (_dio == null) return false;
    try {
      await _dio!.post('/ingest/diagnostics', data: {
        'environment': _environment,
        'report': _trim(report, 200000),
        if (healthScore != null) 'healthScore': healthScore.clamp(0, 100),
        if (issues != null) 'issues': issues.take(50).toList(),
        if (_safe(_tenantId) != null) 'tenantId': _safe(_tenantId),
        if (tenantName != null) 'tenantName': tenantName,
        if (userNote != null && userNote.trim().isNotEmpty) 'userNote': userNote.trim(),
        if (_release != null) 'release': _release,
        'device': _device(),
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  // ---------- internos ----------

  static Future<void> _send(Map<String, dynamic> body) async {
    try {
      await _dio!.post('/ingest/errors', data: body);
      unawaited(_flush());
    } catch (_) {
      if (_pending.length < _maxPending) _pending.add(body);
    }
  }

  static Future<void> _flush() async {
    if (_dio == null || _pending.isEmpty) return;
    final batch = List<Map<String, dynamic>>.from(_pending.take(50));
    try {
      await _dio!.post('/ingest/errors/batch', data: {'events': batch});
      _pending.removeRange(0, batch.length);
    } catch (_) {/* se reintenta en el próximo ciclo */}
  }

  /// Errores de red del usuario (sin internet, timeouts) no son bugs nuestros.
  static bool _isNoise(Object e) {
    if (e is DioException) {
      return e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.cancel ||
          (e.response?.statusCode != null && e.response!.statusCode! < 500);
    }
    final s = e.toString();
    return s.contains('SocketException') || s.contains('Failed host lookup') || s.contains('Connection refused');
  }

  static bool _allow(String key) {
    final now = DateTime.now();
    if (now.difference(_windowStart).inSeconds >= 60) {
      _windowStart = now;
      _sentThisMinute = 0;
      if (_lastSent.length > 500) _lastSent.clear();
    }
    if (_sentThisMinute >= _maxPerMinute) return false;
    final last = _lastSent[key];
    if (last != null && now.difference(last).inSeconds < 10) return false;
    _lastSent[key] = now;
    _sentThisMinute++;
    return true;
  }

  static String _messageOf(Object e) {
    if (e is DioException) {
      final req = e.requestOptions;
      return 'HTTP ${e.response?.statusCode ?? '-'} ${req.method} ${req.path}: ${e.message ?? e.type.name}';
    }
    return e.toString();
  }

  static Map<String, dynamic> _device() => {
        'platform': kIsWeb ? 'web' : defaultTargetPlatform.name,
        'mode': kReleaseMode ? 'release' : (kProfileMode ? 'profile' : 'debug'),
      };

  static String? _safe(OpsValueGetter? f) {
    try {
      final v = f?.call();
      return (v == null || v.isEmpty) ? null : v;
    } catch (_) {
      return null;
    }
  }

  static String _trim(String s, int max) => s.length > max ? s.substring(0, max) : s;
}
