import 'package:flutter/material.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/core/widgets/app_pressable.dart';

/// Tarjeta con profundidad "3D" de la guía (§2): sombra en dos capas (la
/// segunda teñida con [tint]), brillo superior, borde interior y radio 20. Si
/// se puede pulsar, se encoge al 0,97.
///
/// Por dentro es un [Card] (los tests lo buscan por tipo). Con [gradient]
/// (p. ej. `tokens.gradientOf(colorDelServicio)`) la tarjeta es de color y el
/// borde es el interior claro; el texto encima debe elegirse con contraste
/// (`readableOn`/`contrastOn`).
class AppCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EdgeInsetsGeometry padding;

  /// `null` = el margen del `CardTheme` (16 a los lados, 6 arriba y abajo).
  final EdgeInsetsGeometry? margin;

  /// Profundidad de 1 a 3 (`elevation1..3`); 0 = plana.
  final int depth;

  /// Color de la luz de la sombra; por defecto, el de la paleta.
  final Color? tint;

  /// Fondo; por defecto, el del `CardTheme`.
  final Color? color;
  final Gradient? gradient;
  final BorderRadius borderRadius;

  /// Nombre accesible del toque (si la tarjeta se puede pulsar).
  final String? semanticLabel;

  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.depth = 2,
    this.tint,
    this.color,
    this.gradient,
    this.borderRadius = AppRadii.cardRadius,
    this.semanticLabel,
  }) : assert(depth >= 0 && depth <= 3);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final cardTheme = theme.cardTheme;
    final shadows = switch (depth) {
      1 => tokens.elevation1(tint: tint),
      2 => tokens.elevation2(tint: tint),
      3 => tokens.elevation3(tint: tint),
      _ => const <BoxShadow>[],
    };
    final themeShape = cardTheme.shape;
    final side = gradient != null
        ? BorderSide(color: tokens.innerBorder)
        : themeShape is RoundedRectangleBorder
            ? themeShape.side
            : BorderSide.none;
    final interactive = onTap != null || onLongPress != null;

    Widget body = Padding(padding: padding, child: child);
    if (interactive) {
      body = InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: borderRadius,
        child: body,
      );
    }
    body = Ink(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: tokens.sheenGradient,
      ),
      child: body,
    );
    final background = gradient;
    if (background != null) {
      body = Ink(
        decoration:
            BoxDecoration(borderRadius: borderRadius, gradient: background),
        child: body,
      );
    }

    Widget card = DecoratedBox(
      decoration: BoxDecoration(borderRadius: borderRadius, boxShadow: shadows),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        color: color ?? cardTheme.color,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: borderRadius, side: side),
        child: body,
      ),
    );
    if (interactive) {
      card = AppPressable(child: card);
      if (semanticLabel != null) {
        card = Semantics(button: true, label: semanticLabel, child: card);
      }
    }
    return Padding(
      padding: margin ??
          cardTheme.margin ??
          const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: card,
    );
  }
}
