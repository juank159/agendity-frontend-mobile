import 'package:get/get.dart';
import 'package:login_signup/features/services/domain/usecases/update_category_usecase.dart';
import '../controller/edit_category_controller.dart';
import '../../../../core/di/modules/services_module.dart';

class EditCategoryBinding extends Bindings {
  @override
  void dependencies() {
    // Asegurarnos de que el módulo de servicios esté inicializado
    if (!Get.isRegistered<UpdateCategoryUseCase>()) {
      ServicesModule.init();
    }

    Get.lazyPut<EditCategoryController>(
      () => EditCategoryController(
        updateCategoryUseCase: Get.find(),
      ),
    );
  }
}
