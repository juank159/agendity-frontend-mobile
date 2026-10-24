import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/config/theme_config.dart';

/// Feedback breve y común de la app (sustituye a los `Get.snackbar` con
/// colores fijos). Usa los tokens del tema, así que respeta el modo oscuro.
///
/// Va por el `ScaffoldMessenger` raíz de `GetMaterialApp` y no por
/// `Get.snackbar`: con Flutter 3.41 el overlay de GetX 4.6.6 no encuentra el
/// `Overlay` ("No Overlay widget found"). Un mensaje nuevo sustituye al
/// anterior, para no apilar avisos repetidos.
abstract final class AppSnackbar {
  static const Duration defaultDuration = Duration(seconds: 3);

  static void success(String message, {String title = 'Listo'}) =>
      show(AppTone.success, message, title: title);

  static void error(String message, {String title = 'Error'}) =>
      show(AppTone.error, message,
          title: title, duration: const Duration(seconds: 4));

  static void info(String message, {String title = 'Aviso'}) =>
      show(AppTone.info, message, title: title);

  static void warning(String message, {String title = 'Atención'}) =>
      show(AppTone.warning, message,
          title: title, duration: const Duration(seconds: 4));

  static void show(
    AppTone tone,
    String message, {
    required String title,
    Duration duration = defaultDuration,
  }) {
    final messenger = Get.rootController.scaffoldMessengerKey.currentState;
    if (messenger == null) return;
    final colors = messenger.context.tokens.tone(tone);

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(12),
          duration: duration,
          backgroundColor: colors.container,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: colors.color.withValues(alpha: 0.4)),
          ),
          showCloseIcon: true,
          closeIconColor: colors.onContainer,
          content: Row(
            children: [
              Icon(_icon(tone), color: colors.color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: colors.onContainer,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      message,
                      style: TextStyle(color: colors.onContainer, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
  }

  static IconData _icon(AppTone tone) {
    switch (tone) {
      case AppTone.info:
        return Icons.info_outline;
      case AppTone.success:
        return Icons.check_circle_outline;
      case AppTone.warning:
        return Icons.warning_amber_rounded;
      case AppTone.error:
        return Icons.error_outline;
    }
  }
}
