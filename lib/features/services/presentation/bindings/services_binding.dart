import 'package:get/get.dart';
import '../../domain/usecases/get_categories_usecase.dart';
import '../../domain/usecases/get_services_usecase.dart';
import '../controller/services_controller.dart';

/// Use cases: `ServicesDependencies` (arranque de la app).
class ServicesBinding extends Bindings {
  /// **Único** registro de [ServicesController]. Lo usan la ruta de
  /// servicios y las de empleados (que listan servicios). `fenix`: tras
  /// borrarse con su ruta o en el logout (`SessionScope`), el siguiente
  /// `Get.find` crea uno nuevo, que carga la lista en `onInit`.
  static void registerController() {
    Get.lazyPut<ServicesController>(
      () => ServicesController(
        getServicesUseCase: Get.find<GetServicesUseCase>(),
        getCategoriesUseCase: Get.find<GetCategoriesUseCase>(),
      ),
      fenix: true,
    );
  }

  @override
  void dependencies() => registerController();
}
