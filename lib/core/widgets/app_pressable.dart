import 'package:flutter/material.dart';
import 'package:login_signup/core/config/theme_config.dart';

/// Encoge [child] al 0,97 mientras se pulsa (guía §2) y vuelve con
/// `easeOutCubic`. No captura el toque: el gesto lo maneja el hijo (un
/// botón o un `InkWell`). Sin animaciones si el sistema las desactiva o si
/// [enabled] es `false`.
class AppPressable extends StatefulWidget {
  final Widget child;
  final bool enabled;

  const AppPressable({super.key, required this.child, this.enabled = true});

  @override
  State<AppPressable> createState() => _AppPressableState();
}

class _AppPressableState extends State<AppPressable> {
  bool _pressed = false;

  void _set(bool pressed) {
    if (_pressed == pressed || !mounted) return;
    setState(() => _pressed = pressed);
  }

  @override
  Widget build(BuildContext context) {
    final animate = widget.enabled && AppMotion.enabled(context);
    return Listener(
      onPointerDown: animate ? (_) => _set(true) : null,
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: animate && _pressed ? AppMotion.pressedScale : 1,
        duration: AppMotion.fast,
        curve: AppMotion.curve,
        child: widget.child,
      ),
    );
  }
}
