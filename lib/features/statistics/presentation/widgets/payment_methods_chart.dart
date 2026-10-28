import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:login_signup/common/enums/payment_method_enum.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/core/utils/formatters.dart';
import '../../domain/entities/payment_method_stats_entity.dart';

/// Nombre para mostrar de un método (los que la app no conoce, tal cual).
String paymentMethodLabel(PaymentMethodStatsEntity stat) =>
    stat.paymentMethod?.displayName ?? stat.method;

/// Ingresos netos por método de pago: gráfico circular y desglose. Los
/// porcentajes se muestran tal como los calcula el backend.
class PaymentMethodsChart extends StatelessWidget {
  final List<PaymentMethodStatsEntity> stats;

  const PaymentMethodsChart({super.key, required this.stats});

  /// Colores del tema para las porciones (se repiten si hay más métodos).
  static List<Color> palette(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = context.tokens;
    return [
      scheme.primary,
      tokens.success.color,
      tokens.warning.color,
      scheme.tertiary,
      tokens.error.color,
      tokens.statusConfirmed.color,
      scheme.secondary,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = palette(context);
    final positive = stats.where((s) => s.total > 0).toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (positive.isNotEmpty)
              SizedBox(
                height: 180,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                    sections: [
                      for (var i = 0; i < stats.length; i++)
                        if (stats[i].total > 0)
                          PieChartSectionData(
                            color: colors[i % colors.length],
                            value: stats[i].total,
                            title: '',
                            radius: 50,
                          ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            for (var i = 0; i < stats.length; i++)
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: CircleAvatar(
                  radius: 8,
                  backgroundColor: colors[i % colors.length],
                ),
                title: Text(paymentMethodLabel(stats[i])),
                subtitle: Text(formatCount(stats[i].count, 'pago', 'pagos')),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatCop(stats[i].total),
                      style: theme.textTheme.bodyLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(formatPercent(stats[i].percentage),
                        style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
