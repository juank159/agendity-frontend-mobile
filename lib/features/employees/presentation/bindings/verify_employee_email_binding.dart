import 'package:get/get.dart';
import 'package:login_signup/features/employees/presentation/controllers/verify_employee_email_controller.dart';

/// Verificación del email de un empleado (`/verify-employee-email`). Los use
/// cases los registra `EmployeesDependencies`.
class VerifyEmployeeEmailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => VerifyEmployeeEmailController(
          requestVerificationCodeUseCase: Get.find(),
          verifyEmployeeEmailUseCase: Get.find(),
        ));
  }
}
