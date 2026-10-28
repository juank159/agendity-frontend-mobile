import 'package:get/get.dart';
import 'package:login_signup/features/appointments/presentation/controllers/appointment_reminder_controller.dart';

/// Ruta de recordatorios. Los use cases los registra
/// `AppointmentsDependencies`; aquí solo el controller.
class AppointmentReminderBinding implements Bindings {
  @override
  void dependencies() => registerController();

  /// También lo usa `AppointmentsBinding` (la home abre los recordatorios).
  static void registerController() {
    if (Get.isRegistered<AppointmentReminderController>()) return;
    Get.lazyPut<AppointmentReminderController>(
      () => AppointmentReminderController(
        getUpcomingAppointmentsUseCase: Get.find(),
        prepareReminderUseCase: Get.find(),
        markReminderSentUseCase: Get.find(),
      ),
    );
  }
}
