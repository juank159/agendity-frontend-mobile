import 'package:get/get.dart';
import 'package:login_signup/features/auth/presentation/controllers/google_auth_controller.dart';
import 'package:login_signup/features/auth/presentation/controllers/register_controller.dart';

/// Registro de un negocio (`/register`). Solo controllers (los use cases los
/// registra `AuthDependencies`).
class RegisterBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => RegisterController(registerUseCase: Get.find()));
    Get.lazyPut(() => GoogleAuthController(googleSignInUseCase: Get.find()));
  }
}
