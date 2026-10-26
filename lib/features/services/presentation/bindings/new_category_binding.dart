import 'package:get/get.dart';
import '../controller/new_category_controller.dart';

/// Use cases: `ServicesDependencies` (arranque de la app).
class NewCategoryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<NewCategoryController>(
      () => NewCategoryController(
        createCategoryUseCase: Get.find(),
      ),
    );
  }
}
