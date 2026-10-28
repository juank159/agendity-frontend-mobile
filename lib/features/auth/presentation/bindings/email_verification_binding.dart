import 'package:get/get.dart';
import 'package:login_signup/features/auth/presentation/controllers/email_verification_controller.dart';

/// Verificación del email del Owner (`/verify-email`, email en `arguments`).
/// Solo el controller (los use cases los registra `AuthDependencies`).
class EmailVerificationBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => EmailVerificationController(
          requestCodeUseCase: Get.find(),
          verifyEmailUseCase: Get.find(),
        ));
  }
}
