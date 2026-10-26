import 'package:get/get.dart';

import 'package:login_signup/features/services/presentation/controller/categories_controller.dart';

/// Use cases: `ServicesDependencies` (arranque de la app).
class CategoriesBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<CategoriesController>()) {
      Get.put<CategoriesController>(
        CategoriesController(
          getCategoriesUseCase: Get.find(),
          updateCategoryStatusUseCase: Get.find(),
        ),
      );
    }
  }
}
