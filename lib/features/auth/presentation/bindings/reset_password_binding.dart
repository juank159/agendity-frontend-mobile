import 'package:get/get.dart';
import 'package:login_signup/features/auth/domain/usecases/reset_password_usecase.dart';
import 'package:login_signup/features/auth/presentation/controllers/reset_password_controller.dart';

class ResetPasswordBinding extends Bindings {
  @override
  void dependencies() {
    // Limpieza de instancias previas si existen
    if (Get.isRegistered<ResetPasswordController>()) {
      Get.delete<ResetPasswordController>(force: true);
    }

    // Asegurarnos que tenemos el caso de uso disponible
    if (!Get.isRegistered<ResetPasswordUseCase>()) {
      // Si no está registrado, verificamos si podemos crearlo usando el repositorio
      Get.lazyPut<ResetPasswordUseCase>(
        () => ResetPasswordUseCase(Get.find()),
        fenix: true,
      );
    }

    // Registrar nueva instancia del controlador
    Get.put<ResetPasswordController>(
      ResetPasswordController(
        resetPasswordUseCase: Get.find<ResetPasswordUseCase>(),
      ),
    );
  }
}
