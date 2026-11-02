import 'package:flutter/material.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/core/widgets/app_pressable.dart';

/// Botón principal de la guía (§3): degradado de la paleta, sombra teñida en
/// dos capas, brillo y borde interior, se encoge al pulsar y muestra la carga
/// dentro del propio botón.
///
/// Por dentro es un [FilledButton] transparente sobre el degradado: conserva
/// la semántica, el foco y el teclado de Material, y los tests lo encuentran
/// con `find.widgetWithText(FilledButton, …)`.
///
/// - [loading]: no se puede pulsar; el texto sigue visible con una ruedita.
/// - Sin [onPressed] (y sin carga): deshabilitado, sin degradado.
/// - [AppGradientButton.fab]: la variante del FAB extendido ("+ Cita").
class AppGradientButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool loading;

  /// Ocupa todo el ancho disponible.
  final bool expand;

  /// Tooltip (el FAB lo usa para su nombre accesible).
  final String? tooltip;

  final bool _fab;

  const AppGradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.expand = false,
    this.tooltip,
  }) : _fab = false;

  /// FAB extendido con degradado y sombra 3D (va en `floatingActionButton`).
  const AppGradientButton.fab({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = Icons.add_rounded,
    this.tooltip,
  })  : loading = false,
        expand = false,
        _fab = true;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = context.tokens;
    final active = onPressed != null || loading;
    final radius = BorderRadius.circular(_fab ? AppRadii.card : AppRadii.field);
    final foreground =
        active ? tokens.onGradient : scheme.onSurface.withValues(alpha: 0.38);
    // Transparente sin color fijo (regla de la Fase 5).
    final clear = scheme.surface.withValues(alpha: 0);

    final style = FilledButton.styleFrom(
      backgroundColor: clear,
      disabledBackgroundColor: clear,
      foregroundColor: foreground,
      disabledForegroundColor: foreground,
      shadowColor: clear,
      surfaceTintColor: clear,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: radius),
      minimumSize: Size(_fab ? 56 : 64, _fab ? 56 : 52),
      padding: EdgeInsets.symmetric(horizontal: _fab ? 22 : 20, vertical: 14),
    ).copyWith(
      overlayColor:
          WidgetStatePropertyAll(tokens.onGradient.withValues(alpha: 0.12)),
    );

    final content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (loading)
          SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: foreground,
            ),
          )
        else if (icon != null)
          Icon(icon, size: 20),
        if (loading || icon != null) const SizedBox(width: 10),
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: _fab ? FontWeight.w700 : FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ),
      ],
    );

    Widget button = AnimatedContainer(
      duration: AppMotion.of(context),
      curve: AppMotion.curve,
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: active ? tokens.primaryGradient : null,
        color: active ? null : scheme.onSurface.withValues(alpha: 0.12),
        boxShadow: active && onPressed != null
            ? tokens.elevation3(tint: tokens.gradientEnd)
            : null,
      ),
      foregroundDecoration: active
          ? BoxDecoration(
              borderRadius: radius,
              border: Border.all(color: tokens.innerBorder),
              gradient: tokens.sheenGradient,
            )
          : null,
      child: FilledButton(
        onPressed: loading ? null : onPressed,
        style: style,
        child: content,
      ),
    );

    if (expand) button = SizedBox(width: double.infinity, child: button);
    button = Semantics(
      liveRegion: loading,
      child:
          AppPressable(enabled: onPressed != null && !loading, child: button),
    );
    final tip = tooltip;
    return tip == null ? button : Tooltip(message: tip, child: button);
  }
}
