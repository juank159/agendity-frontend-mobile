import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/utils/formatters.dart';
import 'package:login_signup/core/widgets/list_state_view.dart';
import 'package:login_signup/features/appointments/domain/entities/appointment_entity.dart';
import 'package:login_signup/features/appointments/presentation/controllers/appointment_feedback.dart';
import 'package:login_signup/features/appointments/presentation/controllers/reschedule_list_controller.dart';
import 'package:login_signup/features/appointments/presentation/widgets/appointment_conflict_ui.dart';
import 'package:login_signup/features/appointments/presentation/widgets/appointment_detail_dialog.dart';
import 'package:login_signup/features/appointments/presentation/widgets/appointment_form_dialog.dart';

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
            emptyIcon: Icons.event_available,
            emptyMessage: 'No hay citas por mover',
            emptySubMessage: 'Aquí salen las citas agendadas sin conexión que '
                'chocaron con otra al sincronizar.',
            builder: (context, appointments) => RefreshIndicator(
              onRefresh: controller.refreshFromServer,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: appointments.length,
                itemBuilder: (context, index) {
                  final a = appointments[index];
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(a.clientName,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          Text('${formatWeekdayDayMonth(a.startTime)} · '
                              '${formatTimeRange(a.startTime, a.endTime)}'
                              '${a.professionalName == null ? '' : ' · ${a.professionalName}'}'),
                          const SizedBox(height: 4),
                          Text(a.rescheduleReason,
                              style: Theme.of(context).textTheme.bodySmall),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () => _open(a),
                                child: const Text('Ver'),
                              ),
                              if (canMove)
                                FilledButton.icon(
                                  onPressed: () => _move(a),
                                  icon: const Icon(Icons.edit_calendar),
                                  label: const Text('Mover'),
                                ),
                            ],
                          ),
                          if (!canMove)
                            Text(
                              'Solo el propietario puede moverla. Avísale o '
                              'cancélala desde el detalle.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          )),
    );
  }
}
