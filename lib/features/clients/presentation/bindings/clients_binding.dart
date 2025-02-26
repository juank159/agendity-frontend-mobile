import 'package:get/get.dart';
import 'package:login_signup/core/di/modules/clients_module.dart'; // Ajusta la ruta
import 'package:login_signup/features/clients/domain/usecases/clients_usecases.dart';
import 'package:login_signup/features/clients/presentation/controller/clients_controller.dart';
import 'package:login_signup/features/clients/presentation/controller/edit_client_controller.dart';

// clients_binding.dart
class ClientsBinding extends Bindings {
  @override
  void dependencies() {
    // Asegurar que el módulo está inicializado
    _initializeClientsModule();

    // Main clients controller
    Get.lazyPut(() => ClientsController(
          getClientsUseCase: Get.find(),
          createClientUseCase: Get.find(),
          importContactsUseCase: Get.find(),
          localStorage: Get.find(),
        ));

    // Edit client controller
    Get.lazyPut(() => EditClientController(
          getClientByIdUseCase: Get.find(),
          updateClientUseCase: Get.find(),
          deleteClientUseCase: Get.find(),
          remoteDataSource: Get.find(),
        ));
  }

  // Método para asegurar que el módulo está inicializado
  void _initializeClientsModule() async {
    try {
      // Verificar si los use cases ya están registrados
      if (!Get.isRegistered<GetClientsUseCase>()) {
        await ClientsModule.init();
        print('ClientsModule inicializado desde ClientsBinding');
      }
    } catch (e) {
      print('Error al inicializar ClientsModule desde binding: $e');
    }
  }
}
