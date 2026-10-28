import 'package:flutter/material.dart';
import 'package:login_signup/core/utils/formatters.dart';
import '../../domain/entities/professional_stats_entity.dart';
import 'stats_card.dart';

/// Ingresos netos por profesional, de mayor a menor.
class ProfessionalsPerformanceWidget extends StatelessWidget {
  final List<ProfessionalStatsEntity> stats;

  const ProfessionalsPerformanceWidget({super.key, required this.stats});

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
                title: stat.professionalName.isEmpty
                    ? 'Profesional'
                    : stat.professionalName,
                subtitle: '${formatCount(stat.appointmentCount, 'cita', 'citas')}'
                    ' · ${formatCount(stat.paymentCount, 'pago', 'pagos')}'
                    ' · promedio ${formatCop(stat.averagePerPayment)}',
                value: formatCop(stat.totalAmount),
                fraction: StatsBarRow.fractionOf(stat.totalAmount, max),
              ),
          ],
        ),
      ),
    );
  }
}
