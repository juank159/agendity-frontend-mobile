import 'package:get/get.dart';
import '../../presentation/controller/new_service_controller.dart';

/// Use cases: `ServicesDependencies` (arranque de la app).
class NewServiceBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => NewServiceController(
          getCategoriesUseCase: Get.find(),
          createServiceUseCase: Get.find(),
        ));
  }
}
