import 'package:get/get.dart';
import 'package:login_signup/features/services/domain/entities/service_entity.dart';
import 'package:login_signup/features/services/domain/usecases/delete_service_usecase.dart';
import 'package:login_signup/features/services/domain/usecases/get_categories_usecase.dart';
import 'package:login_signup/features/services/domain/usecases/update_service_usecase.dart';
import 'package:login_signup/features/services/presentation/controllers/edit_service_controller.dart';

/// Solo el controller: los use cases los registra `ServicesDependencies`.
/// El servicio a editar llega en `Get.arguments`.
class EditServiceBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<EditServiceController>(
      () => EditServiceController(
        getCategoriesUseCase: Get.find<GetCategoriesUseCase>(),
        updateServiceUseCase: Get.find<UpdateServiceUseCase>(),
        deleteServiceUseCase: Get.find<DeleteServiceUseCase>(),
        service: Get.arguments as ServiceEntity,
      ),
    );
  }
}
