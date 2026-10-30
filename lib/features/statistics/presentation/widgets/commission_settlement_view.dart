import 'package:flutter/material.dart';
import 'package:login_signup/core/utils/business_time_zone.dart';
import 'package:login_signup/core/utils/formatters.dart';
import '../../domain/entities/commission_settlement.dart';

/// Totales del período y una fila por profesional (servicios, profesional y
/// negocio), con el detalle por cita al desplegarla.
class CommissionSettlementView extends StatelessWidget {
  final CommissionSettlement settlement;

  /// El Employee ve solo lo suyo: la fila se abre desplegada.
  final bool ownOnly;

  const CommissionSettlementView({
    super.key,
    required this.settlement,
    this.ownOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Total del período · '
                  '${formatCount(settlement.appointmentCount, 'cita completada', 'citas completadas')}',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 12),
                CommissionAmountsRow(amounts: settlement.totals),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        for (final professional in settlement.professionals)
          _ProfessionalCard(professional: professional, expanded: ownOnly),
      ],
    );
  }
}

/// Servicios · Profesional · Negocio, en tres columnas.
class CommissionAmountsRow extends StatelessWidget {
  final CommissionAmounts amounts;
  final bool dense;

  const CommissionAmountsRow(
      {super.key, required this.amounts, this.dense = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Amount('Servicios', amounts.servicesTotal, dense: dense),
        _Amount('Profesional', amounts.professionalTotal,
            dense: dense, highlight: true),
        _Amount('Negocio', amounts.businessTotal, dense: dense),
      ],
    );
  }
}

class _Amount extends StatelessWidget {
  final String label;
  final double value;
  final bool dense;
  final bool highlight;

  const _Amount(this.label, this.value,
      {this.dense = false, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final valueStyle = (dense
            ? theme.textTheme.bodyMedium
            : theme.textTheme.titleMedium)
        ?.copyWith(
            fontWeight: FontWeight.bold,
            color: highlight ? scheme.primary : null);
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: scheme.onSurfaceVariant)),
          Text(formatCop(value), style: valueStyle),
        ],
      ),
    );
  }
}

class _ProfessionalCard extends StatelessWidget {
  final ProfessionalCommission professional;
  final bool expanded;

  const _ProfessionalCard({required this.professional, required this.expanded});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: ExpansionTile(
        key: PageStorageKey('commission-${professional.professionalId}'),
        initiallyExpanded: expanded,
        shape: const Border(),
        title: Text(professional.professionalName,
            style: theme.textTheme.titleMedium),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: CommissionAmountsRow(amounts: professional.amounts, dense: true),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        children: [
          for (final appointment in professional.appointments)
            _AppointmentRow(appointment: appointment),
        ],
      ),
    );
  }
}

class _AppointmentRow extends StatelessWidget {
  final CommissionAppointment appointment;

  const _AppointmentRow({required this.appointment});

  /// En la zona actual del negocio (como la agenda, 6.05).
  DateTime get _date => BusinessTimeZone.toWallClock(
      BusinessTimeZone.toInstant(appointment.date, appointment.timeZone));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted =
        theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Divider(height: 1),
          const SizedBox(height: 6),
          Text('${formatShortDate(_date)} · ${formatTime(_date)} · '
              '${appointment.clientName}'),
          for (final line in appointment.lines)
            Text(
              '${line.serviceName}: ${formatCop(line.price)} × '
              '${formatPercent(line.commissionPercentage)} = '
              '${formatCop(line.commission)}',
              style: muted,
            ),
          const SizedBox(height: 4),
          CommissionAmountsRow(amounts: appointment.amounts, dense: true),
        ],
      ),
    );
  }
}
