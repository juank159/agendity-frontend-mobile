// import 'package:get/get.dart';
// import 'package:login_signup/features/auth/domain/usecases/reset_password_usecase.dart';
// import 'package:login_signup/features/auth/presentation/controllers/reset_password_controller.dart';

// class ResetPasswordBinding extends Bindings {
//   @override
//   void dependencies() {
//     // Limpieza de instancias previas si existen
//     if (Get.isRegistered<ResetPasswordController>()) {
//       Get.delete<ResetPasswordController>(force: true);
//     }

//     // Asegurarnos que tenemos el caso de uso disponible
//     if (!Get.isRegistered<ResetPasswordUseCase>()) {
//       // Si no está registrado, verificamos si podemos crearlo usando el repositorio
//       Get.lazyPut<ResetPasswordUseCase>(
//         () => ResetPasswordUseCase(Get.find()),
//         fenix: true,
//       );
//     }

//     // Registrar nueva instancia del controlador
//     Get.put<ResetPasswordController>(
//       ResetPasswordController(
//         resetPasswordUseCase: Get.find<ResetPasswordUseCase>(),
//       ),
//     );
//   }
// }

import 'package:get/get.dart';
import 'package:login_signup/features/auth/domain/usecases/reset_password_usecase.dart';
import 'package:login_signup/features/auth/domain/usecases/request_password_reset_usecase.dart';
import 'package:login_signup/features/auth/presentation/controllers/reset_password_controller.dart';

class ResetPasswordBinding extends Bindings {
  @override
  void dependencies() {
    // Limpiar recursos previos si existen
    _cleanupPreviousController();

    // Asegurar que tenemos ResetPasswordUseCase disponible
    if (!Get.isRegistered<ResetPasswordUseCase>()) {
      Get.lazyPut<ResetPasswordUseCase>(
        () => ResetPasswordUseCase(Get.find()),
        fenix: true,
      );
    }

    // Asegurar que tenemos RequestPasswordResetUseCase disponible
    if (!Get.isRegistered<RequestPasswordResetUseCase>()) {
      Get.lazyPut<RequestPasswordResetUseCase>(
        () => RequestPasswordResetUseCase(Get.find()),
        fenix: true,
      );
    }

    // Registrar nueva instancia del controlador con AMBOS use cases
    Get.put<ResetPasswordController>(
      ResetPasswordController(
        resetPasswordUseCase: Get.find<ResetPasswordUseCase>(),
        requestPasswordResetUseCase: Get.find<RequestPasswordResetUseCase>(),
      ),
    );

    print('🔑 ResetPasswordController registrado con ambos UseCases');
  }

  /// Libera un `ResetPasswordController` anterior (antes en `AuthModule`).
  static void _cleanupPreviousController() {
    if (!Get.isRegistered<ResetPasswordController>()) return;
    final controller = Get.find<ResetPasswordController>();
    try {
      controller.passwordController.dispose();
      controller.confirmPasswordController.dispose();
    } catch (_) {
      // Ya liberados.
    }
    Get.delete<ResetPasswordController>(force: true);
  }
}
