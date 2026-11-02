import 'package:flutter/material.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/core/utils/formatters.dart';
import '../../domain/entities/employee_stats_entity.dart';
import 'stats_card.dart';

/// Estadísticas de un profesional: resumen, servicios y evolución diaria.
/// Los importes por servicio son el neto repartido por el backend (2.28).
class EmployeeStatsWidget extends StatelessWidget {
  final EmployeeStatsEntity stats;

  const EmployeeStatsWidget({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final summary = stats.summary;
    final maxService = stats.byService
        .fold<double>(0, (value, s) => s.total > value ? s.total : value);
    final maxDay = stats.dailyEvolution
        .fold<double>(0, (value, d) => d.total > value ? d.total : value);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StatsCard(
          title: 'Resumen',
          subtitle: 'Pagos completados menos lo reembolsado',
          icon: Icons.insights_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              StatHero(
                label: 'Ingresos netos',
                value: formatCop(summary.totalAmount),
                icon: Icons.payments_rounded,
              ),
              const SizedBox(height: 10),
              StatTileGrid(tiles: [
                StatTile(
                  label: 'Pagos',
                  value: '${summary.paymentCount}',
                  icon: Icons.receipt_long_rounded,
                  color: tokens.info.color,
                ),
                StatTile(
                  label: 'Citas pagadas',
                  value: '${summary.appointmentCount}',
                  icon: Icons.event_available_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
                StatTile(
                  label: 'Promedio por pago',
                  value: formatCop(summary.averagePerPayment),
                  icon: Icons.analytics_rounded,
                  color: tokens.warning.color,
                ),
              ]),
            ],
          ),
        ),
        StatsCard(
          title: 'Servicios realizados',
          icon: Icons.spa_rounded,
          child: stats.byService.isEmpty
              ? const Text('Sin servicios en este período')
              : Column(
                  children: [
                    for (final service in stats.byService)
                      StatsBarRow(
                        title: service.serviceName.isEmpty
                            ? 'Servicio'
                            : service.serviceName,
                        subtitle: formatCount(
                            service.appointmentCount, 'cita', 'citas'),
                        value: formatCop(service.total),
                        fraction:
                            StatsBarRow.fractionOf(service.total, maxService),
                      ),
                  ],
                ),
        ),
        StatsCard(
          title: 'Ingresos por día',
          icon: Icons.calendar_view_day_rounded,
          child: stats.dailyEvolution.isEmpty
              ? const Text('Sin pagos en este período')
              : Column(
                  children: [
                    for (final day in stats.dailyEvolution)
                      StatsBarRow(
                        title: formatDate(day.day),
                        subtitle:
                            '${formatCount(day.appointmentCount, 'cita', 'citas')}'
                            ' · ${formatCount(day.paymentCount, 'pago', 'pagos')}',
                        value: formatCop(day.total),
                        fraction: StatsBarRow.fractionOf(day.total, maxDay),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}
