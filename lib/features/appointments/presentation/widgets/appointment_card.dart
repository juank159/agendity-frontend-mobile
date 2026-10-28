import 'package:flutter/material.dart';
import 'package:login_signup/core/utils/formatters.dart';
import 'package:login_signup/features/appointments/domain/entities/appointment_entity.dart';
import 'package:login_signup/features/appointments/presentation/widgets/appointment_status_ui.dart';
import 'package:login_signup/shared/utils/color_hex.dart';
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
    final avatarColor = a.primaryColor;
    final services =
        a.serviceNames.isEmpty ? 'Sin servicios' : a.serviceNames.join(', ');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: avatarColor,
                  child: Text(
                    a.clientName.isEmpty ? '?' : a.clientName[0].toUpperCase(),
                    style: TextStyle(color: contrastOn(avatarColor)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(a.clientName,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(services),
                      const SizedBox(height: 6),
                      Text(
                        '${formatWeekdayDayMonth(a.startTime)} · '
                        '${formatTime(a.startTime)}',
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 6),
                      Wrap(spacing: 6, runSpacing: 4, children: [
                        AppointmentChip.status(context, a.status),
                        AppointmentChip.payment(context, a.paymentStatus),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
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
      ),
    );
  }
}
