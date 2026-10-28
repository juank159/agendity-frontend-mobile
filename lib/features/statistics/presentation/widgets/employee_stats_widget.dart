import 'package:flutter/material.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/core/utils/formatters.dart';
import '../../domain/entities/employee_stats_entity.dart';
import 'stats_card.dart';

/// Estadísticas de un profesional: resumen, servicios y evolución diaria.
/// Los importes por servicio se muestran tal como los calcula el backend
/// (hoy, precio de lista × veces; tarea 2.28).
class EmployeeStatsWidget extends StatelessWidget {
  final EmployeeStatsEntity stats;

  const EmployeeStatsWidget({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final summary = stats.summary;
    final maxService = stats.byService
        .fold<double>(0, (value, s) => s.total > value ? s.total : value);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StatsCard(
          title: 'Resumen',
          subtitle: 'Pagos completados menos lo reembolsado',
          child: Column(
            children: [
              StatTile(
                label: 'Ingresos netos',
                value: formatCop(summary.totalAmount),
                icon: Icons.payments_outlined,
                color: tokens.success.color,
              ),
              const SizedBox(height: 12),
              StatTile(
                label: 'Pagos',
                value: '${summary.paymentCount}',
                icon: Icons.receipt_long_outlined,
                color: tokens.info.color,
              ),
              const SizedBox(height: 12),
              StatTile(
                label: 'Citas pagadas',
                value: '${summary.appointmentCount}',
                icon: Icons.event_available_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 12),
              StatTile(
                label: 'Promedio por pago',
                value: formatCop(summary.averagePerPayment),
                icon: Icons.analytics_outlined,
                color: tokens.warning.color,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        StatsCard(
          title: 'Servicios realizados',
          child: stats.byService.isEmpty
              ? const Text('Sin servicios en este período')
              : Column(
                  children: [
                    for (final service in stats.byService)
                      StatsBarRow(
                        title: service.serviceName.isEmpty
                            ? 'Servicio'
                            : service.serviceName,
                        subtitle: service.count == 1
                            ? '1 vez'
                            : '${service.count} veces',
                        value: formatCop(service.total),
                        fraction:
                            StatsBarRow.fractionOf(service.total, maxService),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 16),
        StatsCard(
          title: 'Ingresos por día',
          child: stats.dailyEvolution.isEmpty
              ? const Text('Sin pagos en este período')
              : Column(
                  children: [
                    for (final day in stats.dailyEvolution)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        title: Text(formatDate(day.day)),
                        subtitle: Text(
                            day.count == 1 ? '1 pago' : '${day.count} pagos'),
                        trailing: Text(formatCop(day.total)),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}
