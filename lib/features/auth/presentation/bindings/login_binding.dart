// lib/features/auth/presentation/bindings/login_binding.dart

import 'package:get/get.dart';
import '../controllers/login_controller.dart';
import '../../domain/usecases/login_usecase.dart';

class LoginBinding extends Bindings {
  @override
  void dependencies() {
    print('🔗 LoginBinding: Verificando dependencias...');

    // Las dependencias de auth deben permanecer después del logout
    // Solo verificar que existan y crear el controller si es necesario
    
    if (Get.isRegistered<LoginUseCase>()) {
      print('✅ LoginUseCase disponible');
      
      // Crear LoginController solo si no existe
      if (!Get.isRegistered<LoginController>()) {
        Get.lazyPut<LoginController>(
          () => LoginController(
            loginUseCase: Get.find<LoginUseCase>(),
          ),
        );
        print('✅ LoginController creado');
      } else {
        print('✅ LoginController ya existe');
      }
    } else {
      print('❌ LoginUseCase no disponible - dependencias de auth no inicializadas');
      // Esto no debería suceder si el logout preserva las dependencias de auth
      throw Exception('Dependencias de autenticación no disponibles');
    }

    print('✅ LoginBinding completado');
  }
}
