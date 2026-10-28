import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/routes/routes.dart';
import 'package:login_signup/core/widgets/error_state.dart';
import 'package:login_signup/features/appointments/presentation/controllers/appointments_controller.dart';
import 'package:login_signup/features/appointments/presentation/widgets/appointment_calendar.dart';
import 'package:login_signup/features/appointments/presentation/widgets/appointment_form_dialog.dart';
import 'package:login_signup/features/appointments/presentation/widgets/view_selector_bottom_sheet.dart';
import 'package:login_signup/shared/custom_drawer.dart';
import 'package:login_signup/shared/widgets/business_time_zone_notice.dart';

/// Home: la agenda. El Owner ve las citas de todo el negocio; el Employee,
/// "Mis citas" (filtra el backend). Los dos pueden agendar: el Employee,
/// solo para sí.
class AppointmentsView extends GetView<AppointmentsController> {
  const AppointmentsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(controller.title)),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_view_day),
            tooltip: 'Cambiar vista',
            onPressed: () => ViewSelectorBottomSheet.show(controller),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'Recordatorios',
            onPressed: () => Get.toNamed(GetRoutes.notifications),
          ),
        ],
      ),
      drawer: const CustomDrawer(),
      body: Column(
        children: [
          // Solo si el dispositivo está en otra zona que el negocio (D-15).
          const BusinessTimeZoneNotice(),
          Expanded(
            child: Obx(() {
              final failure = controller.error.value;
              if (failure != null && controller.appointments.isEmpty) {
                return ErrorState(
                  message: failure.message,
                  onRetry: controller.reload,
                );
              }
              return const AppointmentCalendar();
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Nueva cita',
        onPressed: () => startNewAppointment(controller),
        child: const Icon(Icons.add),
      ),
    );
  }
}
