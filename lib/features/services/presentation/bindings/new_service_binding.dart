import 'package:get/get.dart';
import 'package:login_signup/features/services/domain/usecases/create_service_usecase.dart';
import 'package:login_signup/features/services/domain/usecases/get_categories_usecase.dart';
import 'package:login_signup/features/services/presentation/controller/new_service_controller.dart';

/// Solo el controller: los use cases los registra `ServicesDependencies`.
class NewServiceBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<NewServiceController>(
      () => NewServiceController(
        getCategoriesUseCase: Get.find<GetCategoriesUseCase>(),
        createServiceUseCase: Get.find<CreateServiceUseCase>(),
      ),
    );
  }
}
