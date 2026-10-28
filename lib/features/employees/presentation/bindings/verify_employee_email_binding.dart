import 'package:get/get.dart';
import 'package:login_signup/features/employees/presentation/controllers/verify_employee_email_controller.dart';

/// Pantalla de verificación del email de un empleado recién creado. Los use
/// cases los registra `EmployeesDependencies`.
class VerifyEmployeeEmailBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<VerifyEmployeeEmailController>(
      VerifyEmployeeEmailController(
        requestVerificationCodeUseCase: Get.find(),
        verifyEmployeeEmailUseCase: Get.find(),
      ),
    );
  }
}
