import 'package:flutter/material.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/shared/widgets/app_card.dart';
import 'package:login_signup/shared/widgets/app_section_header.dart';

/// Tarjeta con título de un bloque de estadísticas (12.07): `AppCard` con
/// su encabezado (ícono en píldora, título y subtítulo).
class StatsCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget child;

  const StatsCard({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSectionHeader(
            icon: icon,
            title: title,
            subtitle: subtitle,
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

/// Indicador (KPI) de un resumen: ícono en una píldora del color, etiqueta
/// y la cifra grande con números tabulares.
class StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const StatTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: AppRadii.fieldRadius,
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: AppRadii.chipRadius,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelMedium
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800)
                  .tabular,
            ),
          ),
        ],
      ),
    );
  }
}

/// Indicadores en una rejilla de dos columnas (una si no caben).
class StatTileGrid extends StatelessWidget {
  final List<Widget> tiles;

  const StatTileGrid({super.key, required this.tiles});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      const gap = 10.0;
      final columns = constraints.maxWidth >= 300 ? 2 : 1;
      final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final tile in tiles) SizedBox(width: width, child: tile),
        ],
      );
    });
  }
}

/// Cifra principal de un resumen sobre el degradado de la paleta
/// ("Ingresos netos"): etiqueta, monto grande tabular y una nota.
class StatHero extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final String? note;

  const StatHero({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.note,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final on = tokens.onGradient;
    final extra = note;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: tokens.primaryGradient,
        borderRadius: AppRadii.fieldRadius,
        border: Border.all(color: tokens.innerBorder),
        boxShadow: tokens.elevation2(tint: tokens.gradientEnd),
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: AppRadii.fieldRadius,
        gradient: tokens.sheenGradient,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: on.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: on, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: theme.textTheme.labelLarge?.copyWith(
                        color: on.withValues(alpha: 0.92),
                        fontWeight: FontWeight.w600)),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(value,
                      maxLines: 1,
                      style: theme.textTheme.headlineMedium
                          ?.copyWith(color: on, fontWeight: FontWeight.w800)
                          .tabular),
                ),
                if (extra != null)
                  Text(extra,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: on.withValues(alpha: 0.85))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Fila de un ranking: nombre, detalle, importe y una barra relativa al
/// mayor de la lista (no a un porcentaje del total, que puede no cuadrar).
/// La barra lleva el degradado de la paleta (o [color]).
class StatsBarRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final String value;

  /// De 0 a 1.
  final double fraction;

  /// Ícono o avatar a la izquierda (opcional).
  final Widget? leading;
  final Color? color;

  const StatsBarRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.fraction,
    this.leading,
    this.color,
  });

  /// [value] / [max] acotado a 0–1 (0 si [max] no es positivo).
  static double fractionOf(double value, double max) =>
      max <= 0 ? 0 : (value / max).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = context.tokens;
    final lead = leading;
    final tint = color;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          if (lead != null) ...[lead, const SizedBox(width: 12)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyLarge
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      value,
                      style: theme.textTheme.bodyLarge
                          ?.copyWith(fontWeight: FontWeight.w800)
                          .tabular,
                    ),
                  ],
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 6),
                Semantics(
                  value: '${(fraction * 100).round()} %',
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest,
                      borderRadius: AppRadii.chipRadius,
                    ),
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: fraction.clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: tint == null
                              ? tokens.primaryGradient
                              : tokens.gradientOf(tint),
                          borderRadius: AppRadii.chipRadius,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
