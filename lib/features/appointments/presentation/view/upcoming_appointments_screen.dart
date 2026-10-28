import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/widgets/list_state_view.dart';
import 'package:login_signup/features/appointments/domain/entities/appointment_entity.dart';
import 'package:login_signup/features/appointments/presentation/controllers/appointment_reminder_controller.dart';
import 'package:login_signup/features/appointments/presentation/widgets/appointment_card.dart';

/// Recordatorios manuales: próximas citas pendientes o confirmadas sin
/// recordatorio (las canceladas no salen). Owner: las del negocio;
/// Employee: las suyas.
class UpcomingAppointmentsScreen
    extends GetView<AppointmentReminderController> {
  const UpcomingAppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recordatorios'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
            onPressed: controller.fetch,
          ),
        ],
      ),
      body: Obx(() => ListStateView<AppointmentEntity>(
            isLoading: controller.isLoading.value,
            error: controller.error.value?.message,
            items: controller.upcoming.toList(),
            onRetry: controller.fetch,
            loadingMessage: 'Cargando citas...',
            emptyIcon: Icons.event_available,
            emptyMessage: 'No hay recordatorios pendientes',
            emptySubMessage:
                'Aquí salen las citas de los próximos 7 días que aún no '
                'tienen recordatorio.',
            builder: (context, appointments) => RefreshIndicator(
              onRefresh: controller.fetch,
              child: ListView.builder(
                itemCount: appointments.length,
                itemBuilder: (context, index) {
                  final appointment = appointments[index];
                  return Obx(() => AppointmentCard(
                        appointment: appointment,
                        isSending: controller.sendingId.value == appointment.id,
                        onSendReminder: () => controller.send(appointment),
                      ));
                },
              ),
            ),
          )),
    );
  }
}
