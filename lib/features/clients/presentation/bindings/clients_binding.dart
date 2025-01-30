import 'package:get/get.dart';
import 'package:login_signup/features/clients/presentation/controller/clients_controller.dart';

class ClientsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ClientsController(
          getClientsUseCase: Get.find(),
          createClientUseCase: Get.find(),
          importContactsUseCase: Get.find(),
          localStorage: Get.find(),
        ));
  }
}
