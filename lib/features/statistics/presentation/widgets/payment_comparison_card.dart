import 'package:flutter/material.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/core/utils/formatters.dart';
import '../../domain/entities/payment_comparison_entity.dart';

/// Período elegido frente al anterior de la misma duración.
class PaymentComparisonCard extends StatelessWidget {
  final PaymentComparisonEntity comparison;

  const PaymentComparisonCard({super.key, required this.comparison});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final current = comparison.currentPeriod;
    final previous = comparison.previousPeriod;
    final change = comparison.change;
    final muted = theme.textTheme.bodySmall
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Actual: ${_period(current)}', style: muted),
        Text('Anterior: ${_period(previous)}', style: muted),
        const Divider(height: 24),
        _ComparisonRow(
          label: 'Ingresos netos',
          current: formatCop(current.totalAmount),
          previous: formatCop(previous.totalAmount),
          percentage: change.amountPercentage,
          difference: change.amountDifference,
        ),
        const SizedBox(height: 16),
        _ComparisonRow(
          label: 'Pagos',
          current: '${current.paymentCount}',
          previous: '${previous.paymentCount}',
          percentage: change.countPercentage,
          difference: change.countDifference.toDouble(),
        ),
        const SizedBox(height: 16),
        _ComparisonRow(
          label: 'Promedio por pago',
          current: formatCop(current.averageAmount),
          previous: formatCop(previous.averageAmount),
          percentage: change.averagePercentage,
          difference: change.averageDifference,
        ),
      ],
    );
  }

  static String _period(PeriodStatsEntity period) {
    final start = formatDate(period.startDate);
    final end = formatDate(period.endDate);
    return start == end ? start : '$start - $end';
  }
}

class _ComparisonRow extends StatelessWidget {
  final String label;
  final String current;
  final String previous;
  /// `null` = sin base (el período anterior en 0).
  final double? percentage;
  final double difference;

  const _ComparisonRow({
    required this.label,
    required this.current,
    required this.previous,
    required this.percentage,
    required this.difference,
  });

  /// Texto del cambio: `12,5 %`, "nuevo" (sin base y hubo algo) o "—".
  static String changeLabel(double? percentage, double difference) {
    if (percentage != null) return formatPercent(percentage.abs());
    return difference > 0 ? 'nuevo' : '—';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = context.tokens;
    final Color color;
    final IconData icon;
    final trend = percentage ?? difference;
    if (trend > 0) {
      color = tokens.success.color;
      icon = Icons.arrow_upward;
    } else if (trend < 0) {
      color = tokens.error.color;
      icon = Icons.arrow_downward;
    } else {
      color = scheme.onSurfaceVariant;
      icon = Icons.remove;
    }
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: scheme.onSurfaceVariant)),
              Text(current,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              Text('Anterior: $previous',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Text(
                changeLabel(percentage, difference),
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
