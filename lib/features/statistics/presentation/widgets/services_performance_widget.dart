import 'package:flutter/material.dart';
import 'package:login_signup/core/utils/formatters.dart';
import '../../domain/entities/service_stats_entity.dart';
import 'stats_card.dart';

/// Servicios de las citas con un pago completado. Muestra los importes y
/// porcentajes tal como los calcula el backend (hoy, precio de lista × veces;
/// tarea 2.28).
class ServicesPerformanceWidget extends StatelessWidget {
  final List<ServiceStatsEntity> stats;

  const ServicesPerformanceWidget({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final max = stats.fold<double>(
        0, (value, s) => s.totalAmount > value ? s.totalAmount : value);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            for (final stat in stats)
              StatsBarRow(
                title: stat.serviceName.isEmpty ? 'Servicio' : stat.serviceName,
                subtitle:
                    '${stat.paymentCount == 1 ? '1 vez' : '${stat.paymentCount} veces'}'
                    ' · ${formatPercent(stat.percentageOfTotal)}',
                value: formatCop(stat.totalAmount),
                fraction: StatsBarRow.fractionOf(stat.totalAmount, max),
              ),
          ],
        ),
      ),
    );
  }
}
