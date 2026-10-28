import 'dart:async';

import 'package:get/get.dart';

/// Cuenta atrás reactiva de un código enviado por email: vigencia del código
/// (verificación de la cuenta, recuperación de contraseña y verificación de
/// empleados) o espera antes de poder reenviarlo. **Única** cuenta atrás de
/// la app (5.10). Quien la crea la cancela en su `onClose` con [dispose].
class CodeCountdown {
  /// Vigencia del código en el backend.
  static const codeLifetime = Duration(minutes: 10);

  final Duration lifetime;
  final void Function()? onExpired;

  CodeCountdown({this.lifetime = codeLifetime, this.onExpired});

  /// Segundos que quedan (0 = terminada o sin empezar).
  final secondsLeft = 0.obs;

  Timer? _timer;

  bool get isActive => secondsLeft.value > 0;

  /// `mm:ss` del tiempo restante.
  String get formatted => format(secondsLeft.value);

  /// `mm:ss` de [seconds].
  static String format(int seconds) =>
      '${(seconds ~/ 60).toString().padLeft(2, '0')}:'
      '${(seconds % 60).toString().padLeft(2, '0')}';

  /// Empieza (o reinicia) la cuenta tras enviar un código.
  void start() {
    _timer?.cancel();
    secondsLeft.value = lifetime.inSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  /// La detiene sin avisar de que venció (p. ej. al verificar el código).
  void stop() {
    _timer?.cancel();
    secondsLeft.value = 0;
  }

  void dispose() => _timer?.cancel();

  void _tick() {
    if (secondsLeft.value <= 1) {
      stop();
      onExpired?.call();
      return;
    }
    secondsLeft.value--;
  }
}
