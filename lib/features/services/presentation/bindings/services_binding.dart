import 'package:get/get.dart';
import '../../domain/usecases/get_services_usecase.dart';
import '../controller/services_controller.dart';

/// Use cases: `ServicesDependencies` (arranque de la app).
class ServicesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ServicesController>(
      () => ServicesController(
        getServicesUseCase: Get.find<GetServicesUseCase>(),
      ),
    );
  }
}
