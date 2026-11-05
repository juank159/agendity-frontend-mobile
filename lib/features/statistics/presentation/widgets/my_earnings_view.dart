import 'package:flutter/material.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/core/utils/formatters.dart';
import 'package:login_signup/core/widgets/app_fade_in.dart';
import 'package:login_signup/shared/widgets/app_card.dart';
import 'package:login_signup/shared/widgets/app_note.dart';
import 'package:login_signup/shared/widgets/app_section_header.dart';
import '../../domain/entities/commission_settlement.dart';
import 'commission_settlement_view.dart';
import 'stats_card.dart';

/// "Mis ganancias" de la empleada (D-27), en palabras sencillas:
/// - **Ganado**: su comisión de las citas completadas del período.
/// - **Por ganar**: su comisión de las citas pendientes o confirmadas; pasa
///   a Ganado cuando el negocio completa la cita.
/// - El detalle de cada cita (fecha, cliente, servicios, precio, % y su
///   comisión). **Nunca** lo que le queda al negocio.
class MyEarningsView extends StatelessWidget {
  final CommissionSettlement settlement;

  const MyEarningsView({super.key, required this.settlement});

  static const pendingNote =
      'Se suma a Ganado cuando el negocio complete la cita.';

  @override
  Widget build(BuildContext context) {
    final pending = settlement.pending;
    final earned = settlement.appointments;
    final toEarn = pending?.appointments ?? const <CommissionAppointment>[];
    var index = 0;
    Widget row(CommissionAppointment appointment) => AppFadeIn(
          index: index++,
          child:
              CommissionAppointmentRow(appointment: appointment, ownOnly: true),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 6),
        StatHero(
          key: const Key('earnings-earned'),
          label: 'Ganado',
          value: formatCop(settlement.totals.professionalTotal),
          icon: Icons.savings_rounded,
          note: formatCount(settlement.appointmentCount, 'cita completada',
              'citas completadas'),
        ),
        if (pending != null) _PendingCard(pending: pending),
        if (earned.isNotEmpty) ...[
          const AppSectionHeader(
            icon: Icons.check_circle_rounded,
            title: 'Citas completadas',
            subtitle: 'Lo que ya ganaste',
            padding: EdgeInsets.fromLTRB(0, 18, 0, 2),
          ),
          for (final appointment in earned) row(appointment),
        ],
        if (toEarn.isNotEmpty) ...[
          const AppSectionHeader(
            icon: Icons.hourglass_top_rounded,
            title: 'Por ganar',
            subtitle: 'Citas que el negocio aún no completa',
            padding: EdgeInsets.fromLTRB(0, 18, 0, 2),
          ),
          for (final appointment in toEarn) row(appointment),
        ],
      ],
    );
  }
}

/// "Por ganar": total, cuántas citas y la nota de cuándo pasa a Ganado.
class _PendingCard extends StatelessWidget {
  final CommissionSettlement pending;

  const _PendingCard({required this.pending});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tone = context.tokens.tone(AppTone.warning);
    return AppCard(
      key: const Key('earnings-pending'),
      margin: const EdgeInsets.only(top: 10),
      depth: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: tone.container,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.hourglass_top_rounded,
                    color: tone.onContainer, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Por ganar',
                        style: theme.textTheme.labelLarge?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600)),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        formatCop(pending.totals.professionalTotal),
                        maxLines: 1,
                        style: theme.textTheme.headlineSmall
                            ?.copyWith(
                                color: scheme.onSurface,
                                fontWeight: FontWeight.w800)
                            .tabular,
                      ),
                    ),
                    Text(
                      formatCount(pending.appointmentCount,
                          'cita sin completar', 'citas sin completar'),
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const AppNote(
            MyEarningsView.pendingNote,
            tone: AppTone.info,
            icon: Icons.info_outline_rounded,
            margin: EdgeInsets.only(top: 12),
          ),
        ],
      ),
    );
  }
}
