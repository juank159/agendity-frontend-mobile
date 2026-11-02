import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:login_signup/common/enums/payment_method_enum.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/core/utils/formatters.dart';
import 'package:login_signup/shared/widgets/payment_method_ui.dart';
import '../../domain/entities/payment_method_stats_entity.dart';

/// Nombre para mostrar de un método (los que la app no conoce, tal cual).
String paymentMethodLabel(PaymentMethodStatsEntity stat) =>
    stat.paymentMethod?.displayName ?? stat.method;

/// Ingresos netos por método de pago: gráfico circular y desglose. Los
/// porcentajes se muestran tal como los calcula el backend.
class PaymentMethodsChart extends StatelessWidget {
  final List<PaymentMethodStatsEntity> stats;

  const PaymentMethodsChart({super.key, required this.stats});

  /// Colores de las porciones: los de la paleta del negocio primero
  /// (primario, acento y terciario) y luego los de estado; se repiten si
  /// hay más métodos. Nada fijo: todo sale del tema.
  static List<Color> palette(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = context.tokens;
    return [
      scheme.primary,
      tokens.success.color,
      tokens.warning.color,
      scheme.tertiary,
      tokens.accent,
      tokens.statusConfirmed.color,
      tokens.error.color,
      scheme.secondary,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final colors = palette(context);
    final positive = stats.where((s) => s.total > 0).toList();
    final total = positive.fold<double>(0, (sum, s) => sum + s.total);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (positive.isNotEmpty)
          SizedBox(
            height: 190,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 3,
                    centerSpaceRadius: 52,
                    sections: [
                      for (var i = 0; i < stats.length; i++)
                        if (stats[i].total > 0)
                          PieChartSectionData(
                            color: colors[i % colors.length],
                            value: stats[i].total,
                            title: '',
                            radius: 34,
                            borderSide: BorderSide(
                                color: scheme.surface, width: 1.5),
                          ),
                    ],
                  ),
                ),
                Semantics(
                  label: 'Total por métodos: ${formatCop(total)}',
                  excludeSemantics: true,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Total',
                          style: theme.textTheme.labelMedium
                              ?.copyWith(color: scheme.onSurfaceVariant)),
                      Text(formatCop(total),
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w800)
                              .tabular),
                    ],
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        for (var i = 0; i < stats.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: colors[i % colors.length].withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: colors[i % colors.length], width: 1.5),
                  ),
                  child: Icon(paymentMethodIcon(stats[i].paymentMethod),
                      size: 17, color: colors[i % colors.length]),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(paymentMethodLabel(stats[i]),
                          style: theme.textTheme.bodyLarge
                              ?.copyWith(fontWeight: FontWeight.w600)),
                      Text(formatCount(stats[i].count, 'pago', 'pagos'),
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatCop(stats[i].total),
                      style: theme.textTheme.bodyLarge
                          ?.copyWith(fontWeight: FontWeight.w800)
                          .tabular,
                    ),
                    Text(formatPercent(stats[i].percentage),
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant)
                            .tabular),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}
