import 'dart:async';

import 'package:get/get.dart';

/// Cuenta atrás de un código enviado por email (verificación y recuperación
/// de contraseña): vigencia del código en el backend. Quien la crea la
/// cancela en su `onClose` con [dispose].
class CodeCountdown {
  /// Vigencia del código en el backend.
  static const codeLifetime = Duration(minutes: 10);

  final Duration lifetime;
  final void Function()? onExpired;

  CodeCountdown({this.lifetime = codeLifetime, this.onExpired});

  /// Segundos que le quedan al código (0 = sin código vigente).
  final secondsLeft = 0.obs;

  Timer? _timer;

  bool get isActive => secondsLeft.value > 0;

  /// `mm:ss` del tiempo restante.
  String get formatted {
    final seconds = secondsLeft.value;
    return '${(seconds ~/ 60).toString().padLeft(2, '0')}:'
        '${(seconds % 60).toString().padLeft(2, '0')}';
  }

  /// Empieza (o reinicia) la cuenta tras enviar un código.
  void start() {
    _timer?.cancel();
    secondsLeft.value = lifetime.inSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

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
