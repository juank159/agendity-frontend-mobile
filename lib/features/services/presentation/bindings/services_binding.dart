import 'package:get/get.dart';
import '../../domain/usecases/get_services_usecase.dart';
import '../controller/services_controller.dart';
import '../../../../core/di/modules/services_module.dart'; // Asegúrate de tener este módulo

class ServicesBinding extends Bindings {
  @override
  void dependencies() {
    // Primero verificamos si ya existe el caso de uso
    if (!Get.isRegistered<GetServicesUseCase>()) {
      // Si no existe, inicializamos el módulo de servicios
      ServicesModule.init(); // Esto debería inicializar GetServicesUseCase
    }

    // Ahora podemos inicializar el controlador
    Get.lazyPut<ServicesController>(
      () => ServicesController(
        getServicesUseCase: Get.find<GetServicesUseCase>(),
      ),
    );
  }
}
