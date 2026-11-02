import 'package:get/get.dart';
import 'package:login_signup/features/appointments/presentation/controllers/agenda_summary_controller.dart';
import 'package:login_signup/features/appointments/presentation/controllers/appointment_actions_controller.dart';
import 'package:login_signup/features/appointments/presentation/controllers/appointments_controller.dart';
import 'package:login_signup/features/appointments/presentation/controllers/sync_attention_controller.dart';
import 'package:login_signup/features/auth/presentation/controllers/email_verification_notice_controller.dart';
import 'package:login_signup/features/payments/domain/usecases/get_payments_in_review_usecase.dart';
import 'package:login_signup/features/payments/presentation/controllers/payment_controller.dart';
import 'package:login_signup/features/statistics/domain/usecases/get_payment_stats_usecase.dart';

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
    // Cabecera "Hola…" con los números de hoy (12.04): se recalcula cuando
    // cambia la lista de la agenda. "Ingresos hoy" = pagos de hoy (12.05),
    // con el mismo use case que Informes.
    Get.lazyPut<AgendaSummaryController>(
      () => AgendaSummaryController(
        getAppointmentsUseCase: Get.find(),
        getAppointmentBalanceUseCase: Get.find(),
        getPaymentStatsUseCase: Get.isRegistered<GetPaymentStatsUseCase>()
            ? Get.find<GetPaymentStatsUseCase>()
            : null,
        agendaChanges: Get.find<AppointmentsController>().appointments,
      ),
      fenix: true,
    );
    Get.lazyPut<AppointmentActionsController>(
      () => AppointmentActionsController(
        cancelAppointmentUseCase: Get.find(),
        completeAppointmentUseCase: Get.find(),
        getAppointmentUseCase: Get.find(),
        getAppointmentBalanceUseCase: Get.find(),
        getPaymentsInReviewUseCase: Get.find<GetPaymentsInReviewUseCase>(),
        // Recordatorio por WhatsApp desde el detalle (12.07).
        prepareReminderUseCase: Get.find(),
        markReminderSentUseCase: Get.find(),
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
    // Citas por mover y pagos por revisar tras sincronizar (10.03).
    Get.lazyPut<SyncAttentionController>(
      () => SyncAttentionController(
        getAppointmentsToRescheduleUseCase: Get.find(),
        getPaymentsInReviewUseCase: Get.find<GetPaymentsInReviewUseCase>(),
        session: Get.find(),
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
