import 'package:get/get.dart';
import 'package:login_signup/features/clients/presentation/controller/clients_controller.dart';
import 'package:login_signup/features/clients/presentation/controller/edit_client_controller.dart';

// clients_binding.dart
class ClientsBinding extends Bindings {
  @override
  void dependencies() {
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
}
