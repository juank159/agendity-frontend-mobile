// // lib/features/auth/presentation/bindings/email_verification_binding.dart
// import 'package:get/get.dart';
// import 'package:login_signup/features/auth/presentation/controllers/email_verification_controller.dart';

// class EmailVerificationBinding extends Bindings {
//   @override
//   void dependencies() {
//     // Asegúrate de que AuthModule.init() ya se haya llamado
//     if (!Get.isRegistered<EmailVerificationController>()) {
//       Get.lazyPut<EmailVerificationController>(
//         () => EmailVerificationController(
//           requestCodeUseCase: Get.find(),
//           verifyEmailUseCase: Get.find(),
//         ),
//       );
//     }
//   }
// }

import 'package:get/get.dart';
import 'package:login_signup/features/auth/auth_dependencies.dart';
import '../controllers/email_verification_controller.dart';
import '../../domain/usecases/request_verification_code_usecase.dart';
import '../../domain/usecases/verify_email_usecase.dart';

class EmailVerificationBinding extends Bindings {
  @override
  void dependencies() {
    try {
      print('🔗 Inicializando EmailVerificationBinding...');

      // Asegurar que AuthModule esté inicializado
      if (!Get.isRegistered<RequestVerificationCodeUseCase>() ||
          !Get.isRegistered<VerifyEmailUseCase>()) {
        print('🔄 Inicializando AuthModule desde EmailVerificationBinding...');
        AuthDependencies.init();
      }

      // ← SOLUCIÓN: Forzar eliminación del controlador permanente
      if (Get.isRegistered<EmailVerificationController>()) {
        print(
            '🔄 Eliminando EmailVerificationController existente (forzando)...');
        try {
          Get.delete<EmailVerificationController>(
              force: true); // ← AGREGAR force: true
        } catch (e) {
          print('⚠️ Error eliminando controlador (continuando): $e');
        }
      }

      print('🔧 Creando nuevo EmailVerificationController...');

      // ← CAMBIO: Usar lazyPut en lugar de put para asegurar que onInit se ejecute
      Get.lazyPut<EmailVerificationController>(
        () {
          print('🏭 Factory: Creando EmailVerificationController...');
          return EmailVerificationController(
            requestCodeUseCase: Get.find<RequestVerificationCodeUseCase>(),
            verifyEmailUseCase: Get.find<VerifyEmailUseCase>(),
          );
        },
        fenix: true, // ← IMPORTANTE: Permite recrear cuando se elimine
      );

      print('✅ EmailVerificationBinding inicializado correctamente');
    } catch (e) {
      print('❌ Error en EmailVerificationBinding: $e');
      rethrow;
    }
  }
}
