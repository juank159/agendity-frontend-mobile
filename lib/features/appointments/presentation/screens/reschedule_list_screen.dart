import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/core/utils/formatters.dart';
import 'package:login_signup/core/widgets/app_fade_in.dart';
import 'package:login_signup/core/widgets/app_gradient_button.dart';
import 'package:login_signup/core/widgets/list_state_view.dart';
import 'package:login_signup/features/appointments/domain/entities/appointment_entity.dart';
import 'package:login_signup/features/appointments/presentation/controllers/appointment_feedback.dart';
import 'package:login_signup/features/appointments/presentation/controllers/reschedule_list_controller.dart';
import 'package:login_signup/features/appointments/presentation/widgets/appointment_conflict_ui.dart';
import 'package:login_signup/features/appointments/presentation/widgets/appointment_detail_dialog.dart';
import 'package:login_signup/features/appointments/presentation/widgets/appointment_form_dialog.dart';
import 'package:login_signup/features/appointments/presentation/widgets/appointment_status_ui.dart';
import 'package:login_signup/features/appointments/presentation/widgets/appointment_tile.dart';
import 'package:login_signup/shared/widgets/app_avatar.dart';
import 'package:login_signup/shared/widgets/app_card.dart';
import 'package:login_signup/shared/widgets/app_note.dart';
import 'package:login_signup/shared/widgets/status_chip.dart';

/// "Citas por mover" (10.03): lo agendado sin conexión que al sincronizar
/// chocó (hora ocupada, negocio cerrado…). No ocupan hueco hasta moverlas.
/// Mover es del Owner (editar una cita); la empleada puede abrirla o
/// cancelarla desde el detalle.
class RescheduleListScreen extends GetView<RescheduleListController> {
  const RescheduleListScreen({super.key});

  Future<void> _move(AppointmentEntity appointment) async {
    final saved = await AppointmentFormDialog.edit(appointment);
    if (saved != null) await controller.load();
  }

  Future<void> _open(AppointmentEntity appointment) async {
    await AppointmentDetailsDialog.show(appointment);
    await controller.load();
  }

  @override
  Widget build(BuildContext context) {
    final canMove = AppointmentAccess.canEdit();
    return Scaffold(
      appBar: AppBar(title: const Text('Citas por mover')),
      body: Obx(() => ListStateView<AppointmentEntity>(
            isLoading: controller.isLoading.value,
            error: controller.error.value?.message,
            items: controller.appointments.toList(),
            onRetry: controller.load,
            emptyIcon: Icons.event_available_rounded,
            emptyMessage: 'No hay citas por mover',
            emptySubMessage: 'Aquí salen las citas agendadas sin conexión que '
                'chocaron con otra al sincronizar.',
            builder: (context, appointments) => RefreshIndicator(
              onRefresh: controller.refreshFromServer,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(0, 12, 0, 32),
                itemCount: appointments.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                      child: AppNote(
                        canMove
                            ? 'No ocupan su hora hasta que las muevas a una '
                                'libre.'
                            : 'Solo el propietario puede moverla. Avísale o '
                                'cancélala desde el detalle.',
                        tone: AppTone.warning,
                        icon: Icons.event_repeat_rounded,
                      ),
                    );
                  }
                  final a = appointments[index - 1];
                  return AppFadeIn(
                    index: index - 1,
                    child: _RescheduleCard(
                      appointment: a,
                      canMove: canMove,
                      onOpen: () => _open(a),
                      onMove: () => _move(a),
                    ),
                  );
                },
              ),
            ),
          )),
    );
  }
}

/// Una cita por mover: color del servicio, cliente, cuándo era, el motivo y
/// las acciones.
class _RescheduleCard extends StatelessWidget {
  final AppointmentEntity appointment;
  final bool canMove;
  final VoidCallback onOpen;
  final VoidCallback onMove;

  const _RescheduleCard({
    required this.appointment,
    required this.canMove,
    required this.onOpen,
    required this.onMove,
  });

  @override
  Widget build(BuildContext context) {
    final a = appointment;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = context.tokens;
    final muted = theme.textTheme.bodySmall
        ?.copyWith(color: scheme.onSurfaceVariant, height: 1.35);
    return AppCard(
      tint: tokens.warning.color,
      onTap: onOpen,
      semanticLabel: 'Ver la cita de ${a.clientName}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              AppAvatar(name: a.clientName, radius: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a.clientName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    if (a.professionalName != null)
                      Text('con ${a.professionalName}', style: muted),
                  ],
                ),
              ),
              StatusChip.toReschedule(),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.event_rounded, size: 18, color: scheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${formatWeekdayDayMonth(a.startTime)} · '
                  '${formatTimeRange(a.startTime, a.endTime)}',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600)
                      .tabular,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (var i = 0; i < a.services.length; i++)
                AppointmentServicePill(
                  name: a.services[i].name,
                  color: a.serviceColor(i),
                  foreground: scheme.onSurface,
                  onSurface: true,
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(a.rescheduleReason, style: muted),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: onOpen,
                icon: const Icon(Icons.visibility_rounded),
                label: const Text('Ver'),
              ),
              if (canMove) ...[
                const SizedBox(width: 8),
                AppGradientButton(
                  onPressed: onMove,
                  icon: Icons.edit_calendar_rounded,
                  label: 'Mover',
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
