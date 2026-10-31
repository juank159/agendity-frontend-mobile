import 'package:get/get.dart';
import '../../domain/usecases/get_all_services_usecase.dart';
import '../../domain/usecases/get_categories_usecase.dart';
import '../../domain/usecases/update_service_usecase.dart';
import '../../domain/usecases/get_services_usecase.dart';
import '../controllers/services_controller.dart';

/// Use cases: `ServicesDependencies` (arranque de la app).
class ServicesBinding extends Bindings {
  /// **Único** registro de [ServicesController]. Lo usa la ruta de
  /// servicios (employees pide el catálogo con `GetServicesUseCase`). `fenix`: tras
  /// borrarse con su ruta o en el logout (`SessionScope`), el siguiente
  /// `Get.find` crea uno nuevo, que carga la lista en `onInit`.
  static void registerController() {
    Get.lazyPut<ServicesController>(
      () => ServicesController(
        getServicesUseCase: Get.find<GetServicesUseCase>(),
        getCategoriesUseCase: Get.find<GetCategoriesUseCase>(),
        // Interruptor de activo del Owner (10.03).
        getAllServicesUseCase: Get.isRegistered<GetAllServicesUseCase>()
            ? Get.find<GetAllServicesUseCase>()
            : null,
        updateServiceUseCase: Get.isRegistered<UpdateServiceUseCase>()
            ? Get.find<UpdateServiceUseCase>()
            : null,
      ),
      fenix: true,
    );
  }

  @override
  void dependencies() => registerController();
}
