// import 'package:get/get.dart';
// import 'package:login_signup/features/auth/domain/usecases/request_password_reset_usecase.dart';

// import 'package:login_signup/features/auth/presentation/controllers/forgot_password_controller.dart';

// class ForgotPasswordBinding extends Bindings {
//   @override
//   void dependencies() {
//     Get.lazyPut<RequestPasswordResetUseCase>(
//       () => RequestPasswordResetUseCase(Get.find()),
//     );

//     Get.lazyPut<ForgotPasswordController>(
//       () => ForgotPasswordController(
//         requestPasswordResetUseCase: Get.find(),
//       ),
//     );
//   }
// }

import 'package:get/get.dart';
import 'package:login_signup/features/auth/domain/usecases/request_password_reset_usecase.dart';
import 'package:login_signup/features/auth/presentation/controllers/forgot_password_controller.dart';

class ForgotPasswordBinding extends Bindings {
  @override
  void dependencies() {
    // Asegurar que tenemos RequestPasswordResetUseCase disponible
    if (!Get.isRegistered<RequestPasswordResetUseCase>()) {
      Get.lazyPut<RequestPasswordResetUseCase>(
        () => RequestPasswordResetUseCase(Get.find()),
        fenix: true,
      );
    }

    // Registrar ForgotPasswordController
    Get.put<ForgotPasswordController>(
      ForgotPasswordController(
        requestPasswordResetUseCase: Get.find<RequestPasswordResetUseCase>(),
      ),
    );
  }
}
