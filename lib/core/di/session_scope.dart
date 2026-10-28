import 'package:get/get.dart';
import 'package:login_signup/features/appointments/presentation/controllers/appointment_actions_controller.dart';
import 'package:login_signup/features/appointments/presentation/controllers/appointment_reminder_controller.dart';
import 'package:login_signup/features/appointments/presentation/controllers/appointments_controller.dart';
import 'package:login_signup/features/auth/presentation/controllers/email_verification_controller.dart';
import 'package:login_signup/features/auth/presentation/controllers/email_verification_notice_controller.dart';
import 'package:login_signup/features/clients/presentation/controllers/clients_controller.dart';
import 'package:login_signup/features/clients/presentation/controllers/edit_client_controller.dart';
import 'package:login_signup/features/clients/presentation/controllers/new_client_controller.dart';
import 'package:login_signup/features/employees/presentation/controllers/edit_employee_controller.dart';
import 'package:login_signup/features/employees/presentation/controllers/employees_controller.dart';
import 'package:login_signup/features/employees/presentation/controllers/new_employee_controller.dart';
import 'package:login_signup/features/employees/presentation/controllers/verify_employee_email_controller.dart';
import 'package:login_signup/features/payments/presentation/controllers/payment_controller.dart';
import 'package:login_signup/features/services/presentation/controllers/categories_controller.dart';
import 'package:login_signup/features/services/presentation/controllers/edit_service_controller.dart';
import 'package:login_signup/features/services/presentation/controllers/new_category_controller.dart';
import 'package:login_signup/features/services/presentation/controllers/new_service_controller.dart';
import 'package:login_signup/features/services/presentation/controllers/services_controller.dart';
import 'package:login_signup/features/settings/presentation/controllers/business_settings_controller.dart';
import 'package:login_signup/features/statistics/presentation/controllers/employee_stats_controller.dart';
import 'package:login_signup/features/statistics/presentation/controllers/statistics_controller.dart';
import 'package:login_signup/features/subscriptions/presentation/controllers/subscription_controller.dart';
import 'package:login_signup/features/whatsapp/presentation/controllers/whatsapp_controller.dart';
import 'package:login_signup/core/utils/app_logger.dart';

/// Controllers que guardan datos del usuario que inició sesión.
///
/// Al cerrar sesión se borran **todos** (también los `permanent`), para que
/// la siguiente cuenta no vea datos de la anterior, y la DI vuelve al estado
/// del arranque. No se tocan los de alcance de app (`ThemeController`,
/// `SessionController`, `UserInfoController`, `LogoutController`) ni los
/// formularios de auth (`Login`, `Register`, `ForgotPassword`, `GoogleAuth`),
/// que viven con su ruta.
///
/// Inventario y motivos: ARQUITECTURA §2.2 ("Ciclo de vida de controllers").
abstract final class SessionScope {
  /// Un borrado por controller de feature. Al añadir un controller que guarde
  /// datos de la sesión, se añade aquí.
  static final List<void Function()> featureControllers = [
    deleteSessionController<AppointmentsController>,
    deleteSessionController<AppointmentActionsController>,
    deleteSessionController<AppointmentReminderController>,
    deleteSessionController<PaymentController>,
    deleteSessionController<ClientsController>,
    deleteSessionController<NewClientController>,
    deleteSessionController<EditClientController>,
    deleteSessionController<EmployeesController>,
    deleteSessionController<NewEmployeeController>,
    deleteSessionController<EditEmployeeController>,
    deleteSessionController<VerifyEmployeeEmailController>,
    deleteSessionController<EmailVerificationController>,
    deleteSessionController<EmailVerificationNoticeController>,
    deleteSessionController<ServicesController>,
    deleteSessionController<NewServiceController>,
    deleteSessionController<EditServiceController>,
    deleteSessionController<CategoriesController>,
    deleteSessionController<NewCategoryController>,
    deleteSessionController<StatisticsController>,
    deleteSessionController<EmployeeStatsController>,
    deleteSessionController<SubscriptionController>,
    deleteSessionController<WhatsappController>,
    deleteSessionController<BusinessSettingsController>,
  ];

  /// Borra los controllers de feature. Todos viven con su ruta (desde la
  /// 4.07 ninguno es permanente), así que el arranque no deja ninguno creado.
  static Future<void> reset() async {
    for (final delete in featureControllers) {
      delete();
    }
  }
}

/// Borra [T] aunque sea `permanent`. Si se registró con `fenix`, se conserva
/// la fábrica y el próximo `Get.find` crea una instancia nueva y vacía.
/// Un error en `onClose` no detiene el resto de la limpieza.
void deleteSessionController<T>() {
  if (!Get.isRegistered<T>()) return;
  try {
    Get.delete<T>(force: true);
  } catch (e) {
    AppLogger.error('SessionScope: error al borrar $T', e);
  }
}
