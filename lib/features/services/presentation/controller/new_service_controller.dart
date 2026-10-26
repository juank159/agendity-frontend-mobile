import 'package:get/get.dart';
import 'package:login_signup/features/services/domain/entities/category.dart';
import 'package:login_signup/features/services/domain/usecases/create_service_usecase.dart';
import 'package:login_signup/features/services/presentation/controller/service_form_controller.dart';
import 'package:login_signup/shared/widgets/app_snackbar.dart';

/// Alta de un servicio. Al guardar vuelve a la lista con `result: true`.
class NewServiceController extends ServiceFormController {
  final CreateServiceUseCase _createService;

  NewServiceController({
    required super.getCategoriesUseCase,
    required CreateServiceUseCase createServiceUseCase,
  }) : _createService = createServiceUseCase;

  @override
  void onCategoriesLoaded(List<CategoryEntity> loaded) {
    if (loaded.length == 1 && selectedCategory.value == null) {
      selectedCategory.value = loaded.first;
    }
  }

  @override
  Future<bool> save() async {
    if (isSaving.value) return false;
    final service = buildService();
    if (service == null) return false;

    isSaving.value = true;
    final result = await _createService(service);
    isSaving.value = false;
    return result.fold(
      (failure) {
        showFailure(failure);
        return false;
      },
      (_) {
        Get.back(result: true);
        AppSnackbar.success('Servicio creado');
        return true;
      },
    );
  }
}
