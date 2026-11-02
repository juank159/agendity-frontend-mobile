import 'package:flutter/material.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/core/widgets/app_pressable.dart';

/// Muestras de las paletas (D-22): las usan "Apariencia" (color del
/// dispositivo) y "Mi negocio" (color del negocio). Cada muestra pinta el
/// degradado de su paleta (`ThemeConfig.tokensFor`), no colores fijos.
///
/// Claves para las pruebas: `palette-<id>` (p. ej. `palette-rosa`).

/// Degradado identificativo de [palette] (el de la variante clara: es el
/// mismo en claro y oscuro).
LinearGradient paletteGradient(AppPalette palette) =>
    ThemeConfig.tokensFor(palette, AppThemeVariant.light).primaryGradient;

/// Círculo con el degradado de [palette].
class PaletteDot extends StatelessWidget {
  final AppPalette palette;
  final double size;

  const PaletteDot({super.key, required this.palette, this.size = 32});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final accent = palette.accent;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: paletteGradient(palette),
        border: Border.all(color: tokens.innerBorder, width: 1.5),
      ),
      alignment: Alignment.bottomRight,
      // Grafito: el punto dorado de su acento.
      child: accent == null
          ? null
          : Container(
              width: size * 0.34,
              height: size * 0.34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent,
                border: Border.all(
                    color: Theme.of(context).colorScheme.surface, width: 2),
              ),
            ),
    );
  }
}

/// Muestra grande de una paleta: degradado, nombre y marca si está elegida.
class PaletteSwatch extends StatelessWidget {
  final AppPalette palette;
  final bool selected;
  final VoidCallback? onTap;

  const PaletteSwatch({
    super.key,
    required this.palette,
    required this.selected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final paletteTokens = ThemeConfig.tokensFor(palette, AppThemeVariant.light);
    return Semantics(
      button: true,
      selected: selected,
      label: 'Color ${palette.label}',
      excludeSemantics: true,
      child: AppPressable(
        enabled: onTap != null,
        child: InkWell(
          key: Key('palette-${palette.id}'),
          onTap: onTap,
          borderRadius: AppRadii.cardRadius,
          child: AnimatedContainer(
            duration: AppMotion.of(context),
            curve: AppMotion.curve,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              borderRadius: AppRadii.cardRadius,
              border: Border.all(
                color: selected ? scheme.primary : scheme.outlineVariant,
                width: selected ? 2.5 : 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AspectRatio(
                  aspectRatio: 1.25,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.all(
                          Radius.circular(AppRadii.field)),
                      gradient: paletteTokens.primaryGradient,
                      boxShadow: context.tokens
                          .elevation2(tint: paletteTokens.gradientEnd),
                    ),
                    foregroundDecoration: BoxDecoration(
                      borderRadius: const BorderRadius.all(
                          Radius.circular(AppRadii.field)),
                      border: Border.all(color: paletteTokens.innerBorder),
                      gradient: paletteTokens.sheenGradient,
                    ),
                    alignment: Alignment.center,
                    child: AnimatedOpacity(
                      opacity: selected ? 1 : 0,
                      duration: AppMotion.of(context),
                      child: Icon(Icons.check_circle_rounded,
                          size: 30, color: paletteTokens.onGradient),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  palette.label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    color: selected ? scheme.primary : scheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Rejilla con las 6 paletas (3 por fila). [selected] `null` = ninguna.
class PaletteSwatchGrid extends StatelessWidget {
  final AppPalette? selected;
  final ValueChanged<AppPalette>? onSelected;
  final EdgeInsetsGeometry padding;

  const PaletteSwatchGrid({
    super.key,
    required this.selected,
    this.onSelected,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: LayoutBuilder(builder: (context, constraints) {
        const spacing = 12.0;
        final columns = constraints.maxWidth > 560 ? 6 : 3;
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final palette in AppPalette.values)
              SizedBox(
                width: width,
                child: PaletteSwatch(
                  palette: palette,
                  selected: palette == selected,
                  onTap: onSelected == null ? null : () => onSelected!(palette),
                ),
              ),
          ],
        );
      }),
    );
  }
}
