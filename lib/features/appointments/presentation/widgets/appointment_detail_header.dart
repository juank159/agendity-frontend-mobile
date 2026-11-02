import 'package:flutter/material.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/core/utils/formatters.dart';
import 'package:login_signup/features/appointments/domain/entities/appointment_entity.dart';
import 'package:login_signup/features/appointments/presentation/widgets/appointment_status_ui.dart';
import 'package:login_signup/features/appointments/presentation/widgets/appointment_tile.dart';
import 'package:login_signup/shared/widgets/app_avatar.dart';
import 'package:login_signup/shared/widgets/status_chip.dart';

String _capitalized(String text) =>
    text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);

/// Cabecera con el color del primer servicio (degradado, brillo y borde
/// interior, como la tarjeta de la agenda): cliente con su avatar, día, hora
/// en 12 h con la duración y los estados de la cita y de su pago.
class AppointmentDetailHeader extends StatelessWidget {
  final AppointmentEntity appointment;
  final VoidCallback onClose;

  const AppointmentDetailHeader({super.key, required this.appointment, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final a = appointment;
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final colors = AppointmentTile.colorsFor(a.primaryColor);
    final fg = colors.foreground;
    final phone = a.client.phone;
    final soft = theme.textTheme.bodyMedium
        ?.copyWith(color: fg.withValues(alpha: 0.92), fontWeight: FontWeight.w600);
    return Container(
      decoration: BoxDecoration(gradient: tokens.gradientOf(colors.base)),
      foregroundDecoration: BoxDecoration(
        gradient: tokens.sheenGradient,
        border: Border(bottom: BorderSide(color: tokens.innerBorder)),
      ),
      padding: const EdgeInsets.fromLTRB(18, 16, 6, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppAvatar(name: a.clientName, radius: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a.clientName,
                        style: theme.textTheme.titleLarge?.copyWith(
                            color: fg, fontWeight: FontWeight.w800)),
                    if (phone != null && phone.isNotEmpty)
                      Text(phone, style: soft?.tabular),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Cerrar',
                icon: Icon(Icons.close_rounded, color: fg),
                onPressed: onClose,
              ),
            ],
          ),
          const SizedBox(height: 14),
          _HeaderLine(
            icon: Icons.event_rounded,
            color: fg,
            text: _capitalized(formatLongDate(a.startTime)),
          ),
          const SizedBox(height: 4),
          _HeaderLine(
            icon: Icons.schedule_rounded,
            color: fg,
            strong: true,
            text: '${formatTimeRange(a.startTime, a.endTime)} · '
                '${formatDurationMinutes(a.duration.inMinutes)}',
          ),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 6, children: [
            AppointmentChip.status(context, a.status),
            AppointmentChip.payment(context, a.paymentStatus),
            if (a.needsReschedule) StatusChip.toReschedule(),
          ]),
        ],
      ),
    );
  }
}

class _HeaderLine extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  final bool strong;

  const _HeaderLine({
    required this.icon,
    required this.color,
    required this.text,
    this.strong = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = (strong
            ? Theme.of(context).textTheme.titleMedium
            : Theme.of(context).textTheme.bodyMedium)
        ?.copyWith(
            color: color,
            fontWeight: strong ? FontWeight.w700 : FontWeight.w500)
        .tabular;
    return Row(
      children: [
        Icon(icon, size: 18, color: color.withValues(alpha: 0.9)),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: style)),
      ],
    );
  }
}

