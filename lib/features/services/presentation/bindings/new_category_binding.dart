import 'package:get/get.dart';
import 'package:login_signup/features/services/domain/usecases/create_category_usecase.dart';
import 'package:login_signup/features/services/presentation/controllers/new_category_controller.dart';

/// Solo el controller: los use cases los registra `ServicesDependencies`.
class NewCategoryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<NewCategoryController>(
      () => NewCategoryController(
        createCategoryUseCase: Get.find<CreateCategoryUseCase>(),
      ),
    );
  }
}
