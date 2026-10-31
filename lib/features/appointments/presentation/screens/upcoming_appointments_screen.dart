import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/widgets/list_state_view.dart';
import 'package:login_signup/features/appointments/domain/entities/appointment_entity.dart';
import 'package:login_signup/features/appointments/presentation/controllers/appointment_reminder_controller.dart';
import 'package:login_signup/features/appointments/presentation/widgets/appointment_card.dart';
import 'package:login_signup/features/notifications/presentation/controllers/notifications_controller.dart';
import 'package:login_signup/features/notifications/presentation/widgets/notifications_list.dart';

/// La campana de la agenda (10.03): "Avisos" (los del backend, p. ej. el
/// recordatorio automático) y "Recordatorios" (próximas citas pendientes o
/// confirmadas sin recordatorio manual; Owner: las del negocio; Employee:
/// las suyas).
class UpcomingAppointmentsScreen
    extends GetView<AppointmentReminderController> {
  const UpcomingAppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final hasNotices = Get.isRegistered<NotificationsController>();
    final reminders = _RemindersList(controller: controller);
    if (!hasNotices) {
      return Scaffold(
        appBar: AppBar(title: const Text('Recordatorios')),
        body: reminders,
      );
    }
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Avisos'),
          bottom: const TabBar(tabs: [
            Tab(text: 'Avisos'),
            Tab(text: 'Recordatorios'),
          ]),
        ),
        body: TabBarView(children: [const NotificationsList(), reminders]),
      ),
    );
  }
}

class _RemindersList extends StatelessWidget {
  final AppointmentReminderController controller;

  const _RemindersList({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() => ListStateView<AppointmentEntity>(
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
              onRefresh: controller.refreshFromServer,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
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
          ));
  }
}
