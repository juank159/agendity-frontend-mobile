import 'package:flutter/foundation.dart';

/// Logger mínimo de la app (5.04): escribe solo en debug (`kDebugMode`); en
/// release no sale nada. Sustituye a `print` (prohibido por `avoid_print`) y
/// a `debugPrint` suelto, que sí escribe en release.
///
/// Nunca registrar tokens, contraseñas, códigos ni cuerpos de peticiones.
abstract final class AppLogger {
  /// Destino de las líneas; los tests lo cambian para capturarlas.
  @visibleForTesting
  static void Function(String line) sink = _debugPrint;

  static void _debugPrint(String line) => debugPrint(line);

  /// Traza de desarrollo.
  static void debug(String message) {
    if (kDebugMode) sink(message);
  }

  /// Error que se maneja (no se relanza o se relanza tras registrarlo).
  static void error(String message, [Object? error]) {
    if (kDebugMode) sink(error == null ? message : '$message: $error');
  }
}
