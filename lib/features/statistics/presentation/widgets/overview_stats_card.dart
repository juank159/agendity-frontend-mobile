import 'package:flutter/material.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/core/utils/formatters.dart';
import '../../domain/entities/payment_stats_entity.dart';
import 'stats_card.dart';

/// Resumen del período: ingresos netos (cifra principal sobre el degradado
/// de la paleta), número de pagos y promedio por pago, con números
/// tabulares.
class OverviewStatsCard extends StatelessWidget {
  final PaymentStatsEntity stats;

  const OverviewStatsCard({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return StatsCard(
      title: 'Ingresos del período',
      subtitle: 'Pagos completados menos lo reembolsado',
      icon: Icons.insights_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StatHero(
            label: 'Ingresos netos',
            value: formatCop(stats.totalAmount),
            icon: Icons.payments_rounded,
          ),
          const SizedBox(height: 10),
          StatTileGrid(tiles: [
            StatTile(
              label: 'Pagos',
              value: '${stats.paymentCount}',
              icon: Icons.receipt_long_rounded,
              color: tokens.info.color,
            ),
            StatTile(
              label: 'Promedio por pago',
              value: formatCop(stats.averageAmount),
              icon: Icons.analytics_rounded,
              color: tokens.warning.color,
            ),
          ]),
        ],
      ),
    );
  }
}
