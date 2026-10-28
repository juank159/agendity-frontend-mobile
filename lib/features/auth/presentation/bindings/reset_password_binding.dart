import 'package:get/get.dart';
import 'package:login_signup/features/auth/presentation/controllers/reset_password_controller.dart';

/// Nueva contraseña con el código (`/reset-password`, email en `arguments`).
/// Solo el controller.
class ResetPasswordBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ResetPasswordController(
          resetPasswordUseCase: Get.find(),
          requestPasswordResetUseCase: Get.find(),
        ));
  }
}
