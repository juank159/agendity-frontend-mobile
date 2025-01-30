// lib/features/services/presentation/bindings/new_category_binding.dart
import 'package:get/get.dart';
import 'package:login_signup/features/services/domain/usecases/create_category_usecase.dart';
import '../controller/new_category_controller.dart';
import '../../../../core/di/modules/services_module.dart';

class NewCategoryBinding extends Bindings {
  @override
  void dependencies() {
    // Asegurarnos de que el módulo de servicios esté inicializado
    if (!Get.isRegistered<CreateCategoryUseCase>()) {
      ServicesModule.init();
    }

    Get.lazyPut<NewCategoryController>(
      () => NewCategoryController(
        createCategoryUseCase: Get.find(),
      ),
    );
  }
}
