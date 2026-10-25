// import '../controllers/register_controller.dart';
// import '../../domain/usecases/register_usecase.dart';
// import '../../domain/usecases/request_verification_code_usecase.dart';
// import '../../domain/repositories/auth_repository.dart';
// import 'package:get/get.dart';
// import '../../../../core/di/modules/register_module.dart';
// import '../../../../core/di/modules/auth_module.dart';

// class RegisterBinding extends Bindings {
//   @override
//   void dependencies() {
//     try {
//       print('🔗 Inicializando RegisterBinding...');

//       // PASO 1: Inicializar RegisterModule (para casos específicos de registro)
//       RegisterModule.init();

//       // PASO 2: Asegurar que AuthModule esté inicializado
//       // (AuthModule ya registra todos los UseCases y Controllers necesarios)
//       if (!Get.isRegistered<RegisterController>()) {
//         print(
//             '🔄 RegisterController no encontrado, inicializando AuthModule...');
//         AuthModule.init();
//       }

//       // PASO 3: Verificar que todas las dependencias estén disponibles
//       _verifyDependencies();

//       print('✅ RegisterBinding inicializado correctamente');
//     } catch (e) {
//       print('❌ Error en RegisterBinding: $e');
//       rethrow;
//     }
//   }

//   /// Verificar que todas las dependencias críticas estén registradas
//   void _verifyDependencies() {
//     final dependencies = [
//       'RegisterController',
//       'RequestVerificationCodeUseCase',
//       'RegisterUseCase',
//       'AuthRepository',
//     ];

//     for (String dependency in dependencies) {
//       switch (dependency) {
//         case 'RegisterController':
//           if (!Get.isRegistered<RegisterController>()) {
//             throw Exception('❌ RegisterController no está registrado');
//           }
//           break;
//         case 'RequestVerificationCodeUseCase':
//           if (!Get.isRegistered<RequestVerificationCodeUseCase>()) {
//             throw Exception(
//                 '❌ RequestVerificationCodeUseCase no está registrado');
//           }
//           break;
//         case 'RegisterUseCase':
//           if (!Get.isRegistered<RegisterUseCase>()) {
//             throw Exception('❌ RegisterUseCase no está registrado');
//           }
//           break;
//         case 'AuthRepository':
//           if (!Get.isRegistered<AuthRepository>()) {
//             throw Exception('❌ AuthRepository no está registrado');
//           }
//           break;
//       }
//     }

//     print('✅ Todas las dependencias verificadas correctamente');
//   }
// }

import 'package:get/get.dart';
import '../controllers/google_auth_controller.dart';
import '../../domain/usecases/google_sign_in_usecase.dart';
import '../controllers/register_controller.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/usecases/request_verification_code_usecase.dart';

class RegisterBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<GoogleAuthController>()) {
      Get.lazyPut<GoogleAuthController>(
        () => GoogleAuthController(
          googleSignInUseCase: Get.find<GoogleSignInUseCase>(),
        ),
      );
    }
    print('🔗 RegisterBinding: Verificando dependencias...');

    // Solo verificar que las dependencias existan
    // NO reinicializar módulos completos

    if (!Get.isRegistered<RegisterController>()) {
      print('⚠️ RegisterController no encontrado, pero debería existir');
      // En caso de emergencia, crear uno básico
      Get.lazyPut<RegisterController>(
        () => RegisterController(
          registerUseCase: Get.find<RegisterUseCase>(),
          requestVerificationCodeUseCase:
              Get.find<RequestVerificationCodeUseCase>(),
        ),
      );
    } else {
      print('✅ RegisterController ya existe');
    }

    print('✅ RegisterBinding completado');
  }
}
