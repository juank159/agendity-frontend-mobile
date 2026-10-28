import 'package:get/get.dart';
import 'package:login_signup/features/clients/presentation/controller/clients_controller.dart';
import 'package:login_signup/features/clients/presentation/controller/edit_client_controller.dart';
import 'package:login_signup/features/clients/presentation/controller/new_client_controller.dart';

/// Solo controllers: datasource, repositorio y use cases los registra
/// `ClientsDependencies`.
class ClientsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ClientsController(
          getClientsPageUseCase: Get.find(),
          importClientsUseCase: Get.find(),
        ));

    Get.lazyPut(() => EditClientController(
          getClientByIdUseCase: Get.find(),
          updateClientUseCase: Get.find(),
          deleteClientUseCase: Get.find(),
          uploadClientImageUseCase: Get.find(),
        ));

    Get.lazyPut(() => NewClientController(
          createClientUseCase: Get.find(),
          uploadClientImageUseCase: Get.find(),
        ));
  }
}
