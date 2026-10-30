import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/core/utils/app_logger.dart';

/// Feedback breve y común de la app (sustituye a los `Get.snackbar` con
/// colores fijos). Usa los tokens del tema, así que respeta el modo oscuro.
///
/// Va por el `ScaffoldMessenger` raíz de `GetMaterialApp` y no por
/// `Get.snackbar`: con Flutter 3.41 el overlay de GetX 4.6.6 no encuentra el
/// `Overlay` ("No Overlay widget found"). Un mensaje nuevo sustituye al
/// anterior, para no apilar avisos repetidos.
///
/// Con un diálogo, una hoja inferior o un selector abiertos (ruta
/// `PopupRoute` arriba), el `SnackBar` del Scaffold quedaría debajo de su
/// barrera (7.04-3): entonces el aviso se pinta en el `Overlay` del
/// navegador, por encima de todas las rutas, con el mismo aspecto.
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
    _removeOverlay();
    final overlay = _popupOverlay();
    if (overlay != null) {
      _presentInOverlay(overlay, tone, title, message, duration);
      return;
    }
    final messenger = Get.rootController.scaffoldMessengerKey.currentState;
    if (messenger == null) return;
    final colors = messenger.context.tokens.tone(tone);

    // Sin un Scaffold montado (p. ej. en plena navegación) Flutter lanza una
    // aserción; un aviso perdido no debe romper el flujo que lo pide.
    try {
      _present(messenger, tone, colors, title, message, duration);
    } catch (e) {
      AppLogger.error('AppSnackbar: no se pudo mostrar "$title"', e);
    }
  }

  static OverlayEntry? _overlayEntry;
  static Timer? _overlayTimer;

  /// `true` mientras se ve un aviso pintado sobre un diálogo.
  static bool get isShowingOverOverlay => _overlayEntry != null;

  /// El `Overlay` del navegador raíz si arriba hay una ruta emergente.
  static OverlayState? _popupOverlay() {
    if (Get.routing.route is! PopupRoute) return null;
    return Get.key.currentState?.overlay;
  }

  static void _removeOverlay() {
    _overlayTimer?.cancel();
    _overlayTimer = null;
    final entry = _overlayEntry;
    _overlayEntry = null;
    if (entry == null || !entry.mounted) return;
    try {
      entry.remove();
    } catch (e) {
      AppLogger.error('AppSnackbar: no se pudo quitar el aviso', e);
    }
  }

  static void _presentInOverlay(OverlayState overlay, AppTone tone,
      String title, String message, Duration duration) {
    final entry = OverlayEntry(builder: (context) {
      final colors = context.tokens.tone(tone);
      return Positioned(
        left: 12,
        right: 12,
        bottom: 12 + MediaQuery.of(context).viewInsets.bottom,
        child: SafeArea(
          top: false,
          child: Material(
            color: colors.container,
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: colors.color.withValues(alpha: 0.4)),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
              child: Row(
                children: [
                  Expanded(
                      child: _content(tone, colors, title, message)),
                  IconButton(
                    icon: Icon(Icons.close, color: colors.onContainer),
                    tooltip: 'Cerrar aviso',
                    onPressed: _removeOverlay,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
    try {
      overlay.insert(entry);
    } catch (e) {
      AppLogger.error('AppSnackbar: no se pudo mostrar "$title"', e);
      return;
    }
    _overlayEntry = entry;
    _overlayTimer = Timer(duration, _removeOverlay);
  }

  static void _present(
    ScaffoldMessengerState messenger,
    AppTone tone,
    ToneColors colors,
    String title,
    String message,
    Duration duration,
  ) {
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
          content: _content(tone, colors, title, message),
        ),
      );
  }

  static Widget _content(
          AppTone tone, ToneColors colors, String title, String message) =>
      Row(
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
      );

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
