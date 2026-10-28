import 'package:get/get.dart';
import 'package:login_signup/features/appointments/presentation/controllers/appointment_actions_controller.dart';
import 'package:login_signup/features/appointments/presentation/controllers/appointments_controller.dart';
import 'package:login_signup/features/auth/presentation/controllers/email_verification_notice_controller.dart';
import 'package:login_signup/features/payments/presentation/controllers/payment_controller.dart';

/// Agenda (home). Los use cases los registran los `<feature>_dependencies`;
/// aquí solo los controllers de la ruta. El formulario de la cita y el
/// selector de clientes son efímeros: los crea y borra su diálogo.
class AppointmentsBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AppointmentsController>(
      () => AppointmentsController(
        getAppointmentsUseCase: Get.find(),
        checkSubscriptionLimitsUseCase: Get.find(),
      ),
      fenix: true,
    );
    Get.lazyPut<AppointmentActionsController>(
      () => AppointmentActionsController(
        cancelAppointmentUseCase: Get.find(),
        completeAppointmentUseCase: Get.find(),
        getAppointmentUseCase: Get.find(),
        getAppointmentBalanceUseCase: Get.find(),
      ),
      fenix: true,
    );
    // Diálogo "Registrar pago" (se abre desde el detalle de la cita).
    Get.lazyPut<PaymentController>(
      () => PaymentController(
        createPaymentUseCase: Get.find(),
        getActiveCustomPaymentMethodsUseCase: Get.find(),
      ),
      fenix: true,
    );
    // Aviso "Verifica tu email" del menú lateral de la home (Owner).
    Get.lazyPut<EmailVerificationNoticeController>(
      () => EmailVerificationNoticeController(
        getCurrentUserUseCase: Get.find(),
        session: Get.find(),
      ),
    );
  }
}
