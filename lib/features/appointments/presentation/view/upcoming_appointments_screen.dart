import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/appointment_reminder_controller.dart';
import '../widgets/appointment_card.dart';
import 'package:login_signup/core/widgets/list_state_view.dart';
import 'package:login_signup/features/appointments/domain/entities/appointment_entity.dart';

class UpcomingAppointmentsScreen
    extends GetView<AppointmentReminderController> {
  const UpcomingAppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recordatorio de Citas'),
        actions: [
          // ✅ Botón para refrescar y limpiar automáticamente
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.refreshAndClean(),
            tooltip: 'Refrescar y limpiar',
          ),
          // ✅ Botón para limpiar citas pasadas manualmente
          IconButton(
            icon: const Icon(Icons.cleaning_services),
            onPressed: () => controller.cleanExpiredAppointments(),
            tooltip: 'Limpiar citas pasadas',
          ),
        ],
      ),
      body: Obx(() => ListStateView<AppointmentEntity>(
            isLoading: controller.isLoading.value,
            error: controller.errorMessage.value,
            items: controller.upcomingAppointments,
            onRetry: controller.fetchUpcomingAppointments,
            loadingMessage: 'Cargando citas...',
            emptyIcon: Icons.event_available,
            emptyMessage: 'No hay citas próximas',
            emptySubMessage:
                'Solo se muestran citas futuras que requieren recordatorios.\n'
                'Las citas pasadas se limpian automáticamente.',
            builder: (context, appointments) => RefreshIndicator(
              onRefresh: () => controller.fetchUpcomingAppointments(),
              child: ListView.builder(
                itemCount: appointments.length,
                itemBuilder: (context, index) {
                  final appointment = appointments[index];
                  return AppointmentCard(
                    appointment: appointment,
                    onSendReminder: () =>
                        controller.sendAppointmentReminder(appointment),
                  );
                },
              ),
            ),
          )),
    );
  }
}
