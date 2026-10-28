import 'package:get/get.dart';
import 'package:login_signup/features/auth/presentation/controllers/forgot_password_controller.dart';

/// Recuperar contraseña (`/forgot-password`). Solo el controller.
class ForgotPasswordBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() =>
        ForgotPasswordController(requestPasswordResetUseCase: Get.find()));
  }
}
