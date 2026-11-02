import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/routes/routes.dart';
import 'package:login_signup/core/widgets/error_state.dart';
import 'package:login_signup/core/widgets/app_gradient_button.dart';
import 'package:login_signup/features/appointments/presentation/controllers/appointments_controller.dart';
import 'package:login_signup/features/appointments/presentation/widgets/agenda_summary_header.dart';
import 'package:login_signup/features/appointments/presentation/widgets/appointment_calendar.dart';
import 'package:login_signup/features/appointments/presentation/widgets/appointment_form_dialog.dart';
import 'package:login_signup/features/appointments/presentation/widgets/sync_attention_banner.dart';
import 'package:login_signup/features/appointments/presentation/widgets/view_selector_bottom_sheet.dart';
import 'package:login_signup/shared/custom_drawer.dart';
import 'package:login_signup/shared/widgets/business_time_zone_notice.dart';
import 'package:login_signup/shared/widgets/sync_status_indicator.dart';

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
          const SyncStatusIndicator(),
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Opciones de la agenda',
            onPressed: () => ViewSelectorBottomSheet.show(context, controller),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            tooltip: 'Avisos y recordatorios',
            onPressed: () => Get.toNamed(GetRoutes.notifications),
          ),
        ],
      ),
      drawer: const CustomDrawer(),
      body: Column(
        children: [
          // "Hola, {nombre}", la fecha y los números de hoy (12.04).
          const AgendaSummaryHeader(),
          // Solo si el dispositivo está en otra zona que el negocio (D-15).
          const BusinessTimeZoneNotice(),
          // Citas por mover y pagos por revisar (10.03).
          const SyncAttentionBanner(),
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
      // "+ Cita" (los integration_test lo buscan por el tooltip).
      floatingActionButton: AppGradientButton.fab(
        label: 'Cita',
        tooltip: 'Nueva cita',
        onPressed: () => startNewAppointment(controller),
      ),
    );
  }
}
