import 'package:flutter/material.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/core/utils/formatters.dart';
import '../../domain/entities/payment_stats_entity.dart';
import 'stats_card.dart';

/// Resumen del período: ingresos netos, número de pagos y promedio por pago.
class OverviewStatsCard extends StatelessWidget {
  final PaymentStatsEntity stats;

  const OverviewStatsCard({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return StatsCard(
      title: 'Ingresos del período',
      subtitle: 'Pagos completados menos lo reembolsado',
      child: Column(
        children: [
          StatTile(
            label: 'Ingresos netos',
            value: formatCop(stats.totalAmount),
            icon: Icons.payments_outlined,
            color: tokens.success.color,
          ),
          const SizedBox(height: 12),
          StatTile(
            label: 'Pagos',
            value: '${stats.paymentCount}',
            icon: Icons.receipt_long_outlined,
            color: tokens.info.color,
          ),
          const SizedBox(height: 12),
          StatTile(
            label: 'Promedio por pago',
            value: formatCop(stats.averageAmount),
            icon: Icons.analytics_outlined,
            color: tokens.warning.color,
          ),
        ],
      ),
    );
  }
}
