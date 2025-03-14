// lib/features/auth/presentation/bindings/email_verification_binding.dart
import 'package:get/get.dart';
import 'package:login_signup/features/auth/presentation/controllers/email_verification_controller.dart';

class EmailVerificationBinding extends Bindings {
  @override
  void dependencies() {
    // Asegúrate de que AuthModule.init() ya se haya llamado
    if (!Get.isRegistered<EmailVerificationController>()) {
      Get.lazyPut<EmailVerificationController>(
        () => EmailVerificationController(
          requestCodeUseCase: Get.find(),
          verifyEmailUseCase: Get.find(),
        ),
      );
    }
  }
}
