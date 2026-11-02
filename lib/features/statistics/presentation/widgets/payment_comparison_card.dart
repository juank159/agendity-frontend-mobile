import 'package:flutter/material.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/core/utils/formatters.dart';
import 'package:login_signup/shared/widgets/app_pill.dart';
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
        Row(children: [
          Icon(Icons.date_range_rounded, size: 16, color: muted?.color),
          const SizedBox(width: 6),
          Expanded(
              child: Text('Actual: ${_period(current)}', style: muted)),
        ]),
        Row(children: [
          Icon(Icons.history_rounded, size: 16, color: muted?.color),
          const SizedBox(width: 6),
          Expanded(
              child: Text('Anterior: ${_period(previous)}', style: muted)),
        ]),
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
    final ToneColors? tone;
    final IconData icon;
    final trend = percentage ?? difference;
    if (trend > 0) {
      tone = tokens.success;
      icon = Icons.trending_up_rounded;
    } else if (trend < 0) {
      tone = tokens.error;
      icon = Icons.trending_down_rounded;
    } else {
      tone = null;
      icon = Icons.trending_flat_rounded;
    }
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: theme.textTheme.labelMedium
                      ?.copyWith(color: scheme.onSurfaceVariant)),
              Text(current,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800)
                      .tabular),
              Text('Anterior: $previous',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant)
                      .tabular),
            ],
          ),
        ),
        AppPill(
          label: changeLabel(percentage, difference),
          icon: icon,
          colors: tone,
          tabular: true,
        ),
      ],
    );
  }
}
