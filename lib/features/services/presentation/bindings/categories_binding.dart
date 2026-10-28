import 'package:get/get.dart';
import 'package:login_signup/features/services/domain/usecases/delete_category_usecase.dart';
import 'package:login_signup/features/services/domain/usecases/get_categories_usecase.dart';
import 'package:login_signup/features/services/domain/usecases/update_category_status_usecase.dart';
import 'package:login_signup/features/services/domain/usecases/update_category_usecase.dart';
import 'package:login_signup/features/services/presentation/controllers/categories_controller.dart';

/// Solo el controller: los use cases los registra `ServicesDependencies`.
class CategoriesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CategoriesController>(
      () => CategoriesController(
        getCategoriesUseCase: Get.find<GetCategoriesUseCase>(),
        updateCategoryUseCase: Get.find<UpdateCategoryUseCase>(),
        updateCategoryStatusUseCase: Get.find<UpdateCategoryStatusUseCase>(),
        deleteCategoryUseCase: Get.find<DeleteCategoryUseCase>(),
      ),
      fenix: true,
    );
  }
}
