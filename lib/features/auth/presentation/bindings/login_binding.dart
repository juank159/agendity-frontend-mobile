import 'package:get/get.dart';
import 'package:login_signup/features/auth/presentation/controllers/google_auth_controller.dart';
import 'package:login_signup/features/auth/presentation/controllers/login_controller.dart';

/// Login (`/login`). Registra solo los controllers; los use cases los
/// registra `AuthDependencies`. Viven con la ruta (sin `permanent`).
class LoginBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => LoginController(loginUseCase: Get.find()));
    Get.lazyPut(() => GoogleAuthController(googleSignInUseCase: Get.find()));
  }
}
