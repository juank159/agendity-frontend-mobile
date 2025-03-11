import 'package:get/get.dart';
import '../../../../core/di/modules/register_module.dart';
import '../controllers/register_controller.dart';
import '../../domain/usecases/register_usecase.dart';

class RegisterBinding extends Bindings {
  @override
  void dependencies() {
    try {
      // Inicializar el módulo de registro
      RegisterModule.init();

      // Registrar el controlador
      if (!Get.isRegistered<RegisterController>()) {
        Get.lazyPut<RegisterController>(
          () => RegisterController(
            registerUseCase: Get.find<RegisterUseCase>(),
          ),
          fenix: true,
        );
        print('RegisterController registrado a través del binding');
      } else {
        print('RegisterController ya estaba registrado');
      }
    } catch (e) {
      print('Error en RegisterBinding: $e');
      rethrow;
    }
  }
}
