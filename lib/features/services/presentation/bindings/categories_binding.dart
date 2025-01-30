import 'package:get/get.dart';

import 'package:login_signup/core/di/modules/categories_module.dart';
import 'package:login_signup/features/services/domain/usecases/get_categories_usecase.dart';
import 'package:login_signup/features/services/domain/usecases/update_category_status_usecase.dart';
import 'package:login_signup/features/services/presentation/controller/categories_controller.dart';

class CategoriesBinding extends Bindings {
  @override
  void dependencies() {
    try {
      // Verificar y registrar dependencias necesarias si no existen
      if (!Get.isRegistered<GetCategoriesUseCase>() ||
          !Get.isRegistered<UpdateCategoryStatusUseCase>()) {
        CategoriesModule.init();
      }

      // Registrar el controlador
      if (!Get.isRegistered<CategoriesController>()) {
        Get.put<CategoriesController>(
          CategoriesController(
            getCategoriesUseCase: Get.find(),
            updateCategoryStatusUseCase: Get.find(),
          ),
        );
      }
    } catch (e) {
      print('Error en CategoriesBinding: $e');
      rethrow;
    }
  }
}
