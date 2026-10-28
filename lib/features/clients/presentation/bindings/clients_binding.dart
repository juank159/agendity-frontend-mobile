import 'package:get/get.dart';
import 'package:login_signup/features/clients/presentation/controllers/clients_controller.dart';
import 'package:login_signup/features/clients/presentation/controllers/device_contacts.dart';
import 'package:login_signup/features/clients/presentation/controllers/edit_client_controller.dart';
import 'package:login_signup/features/clients/presentation/controllers/new_client_controller.dart';

/// Lista de clientes (`/clients`). Solo controllers: datasource, repositorio
/// y use cases los registra `ClientsDependencies`.
class ClientsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ClientsController(
          getClientsPageUseCase: Get.find(),
          importClientsUseCase: Get.find(),
          readDeviceContacts: readDeviceContacts,
        ));
  }
}

/// Alta de cliente (`/clients/new`).
class NewClientBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => NewClientController(
          createClientUseCase: Get.find(),
          uploadClientImageUseCase: Get.find(),
        ));
  }
}

/// Edición de cliente (`/clients/edit`, id en `arguments['clientId']`).
class EditClientBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => EditClientController(
          getClientByIdUseCase: Get.find(),
          updateClientUseCase: Get.find(),
          deleteClientUseCase: Get.find(),
          uploadClientImageUseCase: Get.find(),
        ));
  }
}
