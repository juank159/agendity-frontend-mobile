import 'package:flutter/material.dart';
import 'package:login_signup/core/config/theme_config.dart';

/// Entrada de un elemento de lista o sección (guía §2): desvanecido y un
/// desplazamiento corto hacia arriba con `easeOutCubic`. [index] escalona la
/// entrada (40 ms por elemento, hasta el sexto). Sin animaciones si el
/// sistema las desactiva.
///
/// No usa temporizadores (el retraso es un `Interval` dentro de la propia
/// animación), así que `pumpAndSettle` termina en los tests. No bloquea los
/// toques mientras entra.
class AppFadeIn extends StatelessWidget {
  final Widget child;
  final int index;

  /// Desplazamiento inicial en píxeles.
  final double offset;

  const AppFadeIn({
    super.key,
    required this.child,
    this.index = 0,
    this.offset = 12,
  });

  static const _stagger = Duration(milliseconds: 40);
  static const _maxStaggered = 6;

  @override
  Widget build(BuildContext context) {
    if (!AppMotion.enabled(context)) return child;
    final steps = index.clamp(0, _maxStaggered);
    final delay = _stagger * steps;
    final total = AppMotion.slow + delay;
    final start = delay.inMicroseconds / total.inMicroseconds;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: total,
      curve: Interval(start, 1, curve: AppMotion.curve),
      child: child,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, (1 - t) * offset),
          child: child,
        ),
      ),
    );
  }
}
