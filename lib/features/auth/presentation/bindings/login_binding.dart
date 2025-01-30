import 'package:get/get.dart';
import '../../../../core/di/modules/auth_module.dart';
import '../controllers/login_controller.dart';

class LoginBinding extends Bindings {
  @override
  void dependencies() {
    AuthModule.init();

    Get.lazyPut<LoginController>(
      () => LoginController(
        loginUseCase: Get.find(),
      ),
    );
  }
}
