import 'package:flutter/material.dart';
import 'package:login_signup/common/enums/appointment_payment_status_enum.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/core/utils/business_time_zone.dart';
import 'package:login_signup/core/utils/formatters.dart';
import 'package:login_signup/core/widgets/app_fade_in.dart';
import 'package:login_signup/shared/widgets/app_avatar.dart';
import 'package:login_signup/shared/widgets/app_card.dart';
import 'package:login_signup/shared/widgets/app_pill.dart';
import 'package:login_signup/shared/widgets/app_section_header.dart';
import 'package:login_signup/shared/widgets/status_chip.dart';
import '../../domain/entities/commission_settlement.dart';

/// Totales del período y una fila por profesional (servicios, profesional y
/// negocio), con el detalle por cita al desplegarla. Es la vista del Owner;
/// la empleada ve "Mis ganancias" (`MyEarningsView`, D-27).
class CommissionSettlementView extends StatelessWidget {
  final CommissionSettlement settlement;

  const CommissionSettlementView({super.key, required this.settlement});

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
            child: _ProfessionalCard(professional: professional),
          ),
      ],
    );
  }
}

/// Servicios · Profesional · Negocio, en columnas con números tabulares; lo
/// de la profesional resaltado con la paleta. "Negocio" solo sale si
/// [showBusiness] y el servidor lo envió (a la empleada nunca, D-27).
class CommissionAmountsRow extends StatelessWidget {
  final CommissionAmounts amounts;
  final bool dense;

  /// Título de la columna de la profesional ("Tu comisión" para ella).
  final String professionalLabel;
  final bool showBusiness;

  const CommissionAmountsRow({
    super.key,
    required this.amounts,
    this.dense = false,
    this.professionalLabel = 'Profesional',
    this.showBusiness = true,
  });

  @override
  Widget build(BuildContext context) {
    final business = showBusiness ? amounts.businessTotal : null;
    return Row(
      children: [
        _Amount('Servicios', amounts.servicesTotal,
            icon: Icons.spa_rounded, dense: dense),
        SizedBox(width: dense ? 6 : 8),
        _Amount(professionalLabel, amounts.professionalTotal,
            icon: Icons.person_rounded, dense: dense, highlight: true),
        if (business != null) ...[
          SizedBox(width: dense ? 6 : 8),
          _Amount('Negocio', business,
              icon: Icons.storefront_rounded, dense: dense),
        ],
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

  const _ProfessionalCard({required this.professional});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: EdgeInsets.zero,
      depth: 1,
      child: ExpansionTile(
        key: PageStorageKey('commission-${professional.professionalId}'),
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
            CommissionAppointmentRow(appointment: appointment),
        ],
      ),
    );
  }
}

/// Una cita de la liquidación: fecha y hora (zona actual del negocio),
/// cliente, cada servicio con su precio × % = comisión y los importes. Con
/// [ownOnly] (la empleada, D-27) la columna es "Tu comisión", nunca sale lo
/// del negocio y, si la cita está por ganar, se ven su estado y el de pago.
class CommissionAppointmentRow extends StatelessWidget {
  final CommissionAppointment appointment;
  final bool ownOnly;

  const CommissionAppointmentRow(
      {super.key, required this.appointment, this.ownOnly = false});

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
          if (_statusChips() case final chips?) ...[
            const SizedBox(height: 6),
            chips,
          ],
          const SizedBox(height: 4),
          for (final line in appointment.lines)
            Text(
              '${line.serviceName}: ${formatCop(line.price)} × '
              '${formatPercent(line.commissionPercentage)} = '
              '${formatCop(line.commission)}',
              style: muted?.tabular,
            ),
          const SizedBox(height: 6),
          CommissionAmountsRow(
            amounts: appointment.amounts,
            dense: true,
            professionalLabel: ownOnly ? 'Tu comisión' : 'Profesional',
            showBusiness: !ownOnly,
          ),
        ],
      ),
    );
  }

  /// Estado de la cita por ganar y si ya está pagada ("Pagada", "Anticipo",
  /// "Sin pagar"). `null` en las completadas.
  Widget? _statusChips() {
    final status = appointment.status;
    final payment = appointment.paymentStatus;
    if (status == null && payment == null) return null;
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        if (status != null) StatusChip.appointment(status, dense: true),
        if (payment != null)
          StatusChip.payment(payment, dense: true),
        if (payment == AppointmentPaymentStatus.PARTIAL &&
            appointment.paidAmount != null)
          AppPill(
            dense: true,
            tabular: true,
            icon: Icons.payments_rounded,
            label: 'Abonado ${formatCop(appointment.paidAmount)}',
          ),
      ],
    );
  }
}
