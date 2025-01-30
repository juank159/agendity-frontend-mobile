import 'package:get/get.dart';
import 'package:login_signup/features/services/domain/entities/service_entity.dart';
import 'package:login_signup/features/services/domain/usecases/delete_service_usecase.dart';
import 'package:login_signup/features/services/domain/usecases/update_service_usecase.dart';
import 'package:login_signup/features/services/presentation/controller/edit_service_controller.dart';

class EditServiceBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<EditServiceController>(() => EditServiceController(
          updateServiceUseCase: Get.find<UpdateServiceUseCase>(),
          deleteServiceUseCase: Get.find<DeleteServiceUseCase>(),
          service: Get.arguments as ServiceEntity,
        ));
  }
}
