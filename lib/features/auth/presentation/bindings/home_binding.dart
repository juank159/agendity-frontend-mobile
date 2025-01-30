// lib/features/home/presentation/bindings/home_binding.dart
import 'package:get/get.dart';
import 'package:login_signup/features/auth/presentation/controllers/user_info_controller.dart';
import '../../../../core/di/modules/user_module.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    // Asegurarse de que el UserModule esté inicializado
    if (!Get.isRegistered<UserInfoController>()) {
      UserModule.init();
    }

    // Si tienes un controlador específico para el home
    // Get.lazyPut<HomeController>(() => HomeController());
  }
}
