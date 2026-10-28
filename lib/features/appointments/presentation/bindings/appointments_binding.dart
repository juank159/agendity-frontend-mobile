import 'package:get/get.dart';
import 'package:login_signup/features/appointments/presentation/bindings/appointment_reminder_binding.dart';
import 'package:login_signup/features/appointments/presentation/controllers/appointments_controller.dart';
import 'package:login_signup/features/payments/presentation/controllers/payment_controller.dart';

/// Agenda (home). Los use cases los registran los `<feature>_dependencies`;
/// aquí solo los controllers.
class AppointmentsBinding implements Bindings {
  @override
  void dependencies() {
    // Diálogo "Registrar pago" (se abre desde el detalle de la cita).
    Get.lazyPut<PaymentController>(
      () => PaymentController(
        createPaymentUseCase: Get.find(),
        getActiveCustomPaymentMethodsUseCase: Get.find(),
      ),
      fenix: true,
    );
    Get.lazyPut<AppointmentsController>(
      () => AppointmentsController(
        getAppointmentsUseCase: Get.find(),
        createAppointmentUseCase: Get.find(),
        updateAppointmentUseCase: Get.find(),
        getServicesUseCase: Get.find(),
        getClientsPageUseCase: Get.find(),
        getProfessionalsUseCase: Get.find(),
        getProfessionalByIdUseCase: Get.find(),
      ),
      fenix: true,
    );
    AppointmentReminderBinding.registerController();
  }
}
