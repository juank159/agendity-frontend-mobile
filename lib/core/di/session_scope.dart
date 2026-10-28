import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/di/modules/employees_module.dart';
import 'package:login_signup/features/appointments/presentation/controllers/appointment_reminder_controller.dart';
import 'package:login_signup/features/appointments/presentation/controllers/appointments_controller.dart';
import 'package:login_signup/features/auth/presentation/controllers/email_verification_controller.dart';
import 'package:login_signup/features/clients/presentation/controller/clients_controller.dart';
import 'package:login_signup/features/clients/presentation/controller/edit_client_controller.dart';
import 'package:login_signup/features/clients/presentation/controller/new_client_controller.dart';
import 'package:login_signup/features/employees/presentation/controllers/employees_controller.dart';
import 'package:login_signup/features/employees/presentation/controllers/verify_employee_email_controller.dart';
import 'package:login_signup/features/payments/presentation/controllers/payment_controller.dart';
import 'package:login_signup/features/services/presentation/controller/categories_controller.dart';
import 'package:login_signup/features/services/presentation/controller/edit_service_controller.dart';
import 'package:login_signup/features/services/presentation/controller/new_category_controller.dart';
import 'package:login_signup/features/services/presentation/controller/new_service_controller.dart';
import 'package:login_signup/features/services/presentation/controller/services_controller.dart';
import 'package:login_signup/features/statistics/presentation/controllers/employee_stats_controller.dart';
import 'package:login_signup/features/statistics/presentation/controllers/statistics_controller.dart';
import 'package:login_signup/features/subscriptions/presentation/controllers/subscription_controller.dart';
import 'package:login_signup/features/whatsapp/presentation/controllers/whatsapp_controller.dart';

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
    deleteSessionController<AppointmentReminderController>,
    deleteSessionController<PaymentController>,
    deleteSessionController<ClientsController>,
    deleteSessionController<NewClientController>,
    deleteSessionController<EditClientController>,
    deleteSessionController<EmployeesController>,
    deleteSessionController<VerifyEmployeeEmailController>,
    deleteSessionController<EmailVerificationController>,
    deleteSessionController<ServicesController>,
    deleteSessionController<NewServiceController>,
    deleteSessionController<EditServiceController>,
    deleteSessionController<CategoriesController>,
    deleteSessionController<NewCategoryController>,
    deleteSessionController<StatisticsController>,
    deleteSessionController<EmployeeStatsController>,
    deleteSessionController<SubscriptionController>,
    deleteSessionController<WhatsappController>,
  ];

  /// Borra los controllers de feature y vuelve a registrar los que el
  /// arranque deja creados (`EmployeesController`, permanente hasta la 4.07).
  static Future<void> reset() async {
    for (final delete in featureControllers) {
      delete();
    }
    await EmployeesModule.registerController();
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
    debugPrint('SessionScope: error al borrar $T: $e');
  }
}
