import 'package:flutter/material.dart';
import 'package:login_signup/core/config/color_contrast.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/core/utils/formatters.dart';
import 'package:login_signup/features/appointments/domain/entities/appointment_entity.dart';
import 'package:login_signup/features/appointments/presentation/widgets/appointment_status_ui.dart';
import 'package:login_signup/shared/widgets/app_avatar.dart';
import 'package:login_signup/shared/widgets/app_card.dart';
import 'package:login_signup/shared/widgets/whatsapp_icon.dart';

/// Tarjeta de una cita en la lista de recordatorios.
class AppointmentCard extends StatelessWidget {
  final AppointmentEntity appointment;
  final VoidCallback onSendReminder;
  final bool isSending;

  const AppointmentCard({
    super.key,
    required this.appointment,
    required this.onSendReminder,
    this.isSending = false,
  });

  @override
  Widget build(BuildContext context) {
    final a = appointment;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = context.tokens;
    final color = a.primaryColor;
    final services =
        a.serviceNames.isEmpty ? 'Sin servicios' : a.serviceNames.join(', ');

    return AppCard(
      tint: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: tokens.gradientOf(color),
                  border: Border.all(color: tokens.innerBorder),
                  boxShadow: tokens.elevation1(tint: color),
                ),
                child: Text(
                  AppAvatar.initialsOf(a.clientName),
                  style: theme.textTheme.titleSmall?.copyWith(
                      color: readableOn(color), fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a.clientName,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(services,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: scheme.onSurfaceVariant)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.event_rounded,
                            size: 16, color: scheme.primary),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            '${formatWeekdayDayMonth(a.startTime)} · '
                            '${formatTime(a.startTime)}',
                            style: theme.textTheme.bodyMedium?.tabular
                                .copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(spacing: 6, runSpacing: 4, children: [
                      AppointmentChip.status(context, a.status),
                      AppointmentChip.payment(context, a.paymentStatus),
                    ]),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: isSending ? null : onSendReminder,
            icon: isSending
                ? SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: scheme.onPrimary))
                : WhatsappIcon(color: scheme.onPrimary, size: 18),
            label: const Text('Enviar recordatorio'),
          ),
        ],
      ),
    );
  }
}
