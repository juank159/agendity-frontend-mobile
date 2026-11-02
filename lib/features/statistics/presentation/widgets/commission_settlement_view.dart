import 'package:flutter/material.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/core/utils/business_time_zone.dart';
import 'package:login_signup/core/utils/formatters.dart';
import 'package:login_signup/core/widgets/app_fade_in.dart';
import 'package:login_signup/shared/widgets/app_avatar.dart';
import 'package:login_signup/shared/widgets/app_card.dart';
import 'package:login_signup/shared/widgets/app_section_header.dart';
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
        AppCard(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppSectionHeader(
                icon: Icons.percent_rounded,
                title: 'Total del período',
                subtitle: formatCount(settlement.appointmentCount,
                    'cita completada', 'citas completadas'),
                padding: EdgeInsets.zero,
              ),
              const SizedBox(height: 14),
              CommissionAmountsRow(amounts: settlement.totals),
            ],
          ),
        ),
        for (final (index, professional) in settlement.professionals.indexed)
          AppFadeIn(
            index: index,
            child: _ProfessionalCard(
                professional: professional, expanded: ownOnly),
          ),
      ],
    );
  }
}

/// Servicios · Profesional · Negocio, en tres columnas con números
/// tabulares; lo de la profesional resaltado con la paleta.
class CommissionAmountsRow extends StatelessWidget {
  final CommissionAmounts amounts;
  final bool dense;

  const CommissionAmountsRow(
      {super.key, required this.amounts, this.dense = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Amount('Servicios', amounts.servicesTotal,
            icon: Icons.spa_rounded, dense: dense),
        SizedBox(width: dense ? 6 : 8),
        _Amount('Profesional', amounts.professionalTotal,
            icon: Icons.person_rounded, dense: dense, highlight: true),
        SizedBox(width: dense ? 6 : 8),
        _Amount('Negocio', amounts.businessTotal,
            icon: Icons.storefront_rounded, dense: dense),
      ],
    );
  }
}

class _Amount extends StatelessWidget {
  final String label;
  final double value;
  final IconData icon;
  final bool dense;
  final bool highlight;

  const _Amount(this.label, this.value,
      {required this.icon, this.dense = false, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final valueStyle = (dense
            ? theme.textTheme.bodyMedium
            : theme.textTheme.titleMedium)
        ?.copyWith(
            fontWeight: FontWeight.w800,
            color: highlight ? scheme.primary : scheme.onSurface)
        .tabular;
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(dense ? 8 : 10),
        decoration: BoxDecoration(
          color: highlight
              ? scheme.primaryContainer.withValues(alpha: 0.55)
              : scheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: AppRadii.fieldRadius,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon,
                    size: dense ? 13 : 15,
                    color: highlight ? scheme.primary : scheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: scheme.onSurfaceVariant)),
                ),
              ],
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(formatCop(value), maxLines: 1, style: valueStyle),
            ),
          ],
        ),
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
    return AppCard(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: EdgeInsets.zero,
      depth: 1,
      child: ExpansionTile(
        key: PageStorageKey('commission-${professional.professionalId}'),
        initiallyExpanded: expanded,
        shape: const Border(),
        collapsedShape: const Border(),
        leading: AppAvatar(name: professional.professionalName, radius: 20),
        title: Text(professional.professionalName,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700)),
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
    final scheme = theme.colorScheme;
    final muted =
        theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant);
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: AppRadii.fieldRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.event_rounded, size: 16, color: scheme.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${formatShortDate(_date)} · ${formatTime(_date)} · '
                  '${appointment.clientName}',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600)
                      .tabular,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          for (final line in appointment.lines)
            Text(
              '${line.serviceName}: ${formatCop(line.price)} × '
              '${formatPercent(line.commissionPercentage)} = '
              '${formatCop(line.commission)}',
              style: muted?.tabular,
            ),
          const SizedBox(height: 6),
          CommissionAmountsRow(amounts: appointment.amounts, dense: true),
        ],
      ),
    );
  }
}
