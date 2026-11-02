import 'package:flutter/material.dart';
import 'package:login_signup/core/config/theme_config.dart';

/// Píldora de dato de la guía (§3): ícono y texto cortos sobre un contenedor
/// tonal de radio 12 ("45 min", "En línea", "3 servicios", "Propietario").
///
/// Sin [colors] es neutra (superficie del tema). Es la pieza visual de
/// `StatusChip`, que añade la semántica "Estado: …" y los colores de estado;
/// para un **estado** usa `StatusChip`, para un **dato**, esta.
class AppPill extends StatelessWidget {
  final String label;
  final IconData? icon;
  final ToneColors? colors;

  /// Más baja (dentro de tarjetas).
  final bool dense;

  /// Cifras tabulares (montos, horas, conteos).
  final bool tabular;

  const AppPill({
    super.key,
    required this.label,
    this.icon,
    this.colors,
    this.dense = false,
    this.tabular = false,
  });

  /// Colores neutros: los de la superficie del tema.
  static ToneColors neutral(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ToneColors(
      color: scheme.onSurfaceVariant,
      container: scheme.surfaceContainerHighest,
      onContainer: scheme.onSurfaceVariant,
    );
  }

  @override
  Widget build(BuildContext context) {
    final tone = colors ?? neutral(context);
    final pillIcon = icon;
    final style = TextStyle(
      color: tone.onContainer,
      fontSize: dense ? 11 : 12,
      fontWeight: FontWeight.w700,
    );
    return Container(
      padding:
          EdgeInsets.symmetric(horizontal: dense ? 8 : 10, vertical: dense ? 2 : 4),
      decoration: BoxDecoration(
        color: tone.container,
        borderRadius: AppRadii.chipRadius,
        border: Border.all(color: tone.color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (pillIcon != null) ...[
            Icon(pillIcon, size: dense ? 12 : 14, color: tone.color),
            SizedBox(width: dense ? 3 : 4),
          ],
          Text(label, maxLines: 1, style: tabular ? style.tabular : style),
        ],
      ),
    );
  }
}
