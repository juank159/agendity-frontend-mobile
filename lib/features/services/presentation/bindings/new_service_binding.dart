// new_service_binding.dart
import 'package:get/get.dart';
import 'package:login_signup/features/services/domain/usecases/create_service_usecase.dart';
import '../../../../core/di/modules/services_module.dart'; // Añadir esta importación
import '../../presentation/controller/new_service_controller.dart';

class NewServiceBinding extends Bindings {
  @override
  void dependencies() {
    // Asegurarnos de que el módulo de servicios esté inicializado
    if (!Get.isRegistered<CreateServiceUseCase>()) {
      ServicesModule.init();
    }

    Get.lazyPut(() => NewServiceController(
          getCategoriesUseCase: Get.find(),
          createServiceUseCase: Get.find(),
        ));
  }
}
