import 'package:get/get.dart';
import 'package:login_signup/features/appointments/presentation/controllers/appointment_reminder_controller.dart';
import 'package:login_signup/features/notifications/presentation/controllers/notifications_controller.dart';

/// Ruta de la campana (`GetRoutes.notifications`): avisos y recordatorios. Los use cases los
/// registra `AppointmentsDependencies`; aquí solo el controller.
class AppointmentReminderBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AppointmentReminderController>(
      () => AppointmentReminderController(
        getUpcomingAppointmentsUseCase: Get.find(),
        prepareReminderUseCase: Get.find(),
        markReminderSentUseCase: Get.find(),
      ),
    );
    // Pestaña "Avisos" de la campana (10.03).
    Get.lazyPut<NotificationsController>(
      () => NotificationsController(getNotificationsUseCase: Get.find()),
    );
  }
}
