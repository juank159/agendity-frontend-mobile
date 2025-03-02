// lib/features/appointments/presentation/screens/upcoming_appointments_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/appointment_reminder_controller.dart';
import '../widgets/appointment_card.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/loading_state.dart';

class UpcomingAppointmentsScreen
    extends GetView<AppointmentReminderController> {
  const UpcomingAppointmentsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Recordatorio de Citas'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () => controller.fetchUpcomingAppointments(),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return LoadingState(message: 'Cargando citas...');
        }

        if (controller.errorMessage.value.isNotEmpty) {
          return ErrorState(
            message: controller.errorMessage.value,
            onRetry: () => controller.fetchUpcomingAppointments(),
          );
        }

        if (controller.upcomingAppointments.isEmpty) {
          return EmptyState(
            icon: Icons.event_busy,
            message: 'No hay citas próximas',
            subMessage: 'Las próximas aparecerán aquí',
          );
        }

        return RefreshIndicator(
          onRefresh: () => controller.fetchUpcomingAppointments(),
          child: ListView.builder(
            itemCount: controller.upcomingAppointments.length,
            itemBuilder: (context, index) {
              final appointment = controller.upcomingAppointments[index];
              return AppointmentCard(
                appointment: appointment,
                onSendReminder: () =>
                    controller.sendAppointmentReminder(appointment),
              );
            },
          ),
        );
      }),
    );
  }
}
