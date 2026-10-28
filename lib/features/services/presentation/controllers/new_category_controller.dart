import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/features/services/domain/failures/services_failures.dart';
import 'package:login_signup/features/services/domain/usecases/create_category_usecase.dart';
import 'package:login_signup/features/services/presentation/controllers/catalog_access.dart';
import 'package:login_signup/shared/widgets/app_snackbar.dart';

/// Alta de una categoría (solo Owner). Al guardar vuelve con `result: true`.
class NewCategoryController extends GetxController {
  final CreateCategoryUseCase _createCategory;

  NewCategoryController({required CreateCategoryUseCase createCategoryUseCase})
      : _createCategory = createCategoryUseCase;

  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final isSaving = false.obs;

  @override
  void onClose() {
    nameController.dispose();
    descriptionController.dispose();
    super.onClose();
  }

  /// `true` si se creó.
  Future<bool> save() async {
    if (isSaving.value) return false;
    isSaving.value = true;
    final result = await _createCategory(CategoryParams(
      name: nameController.text,
      description: descriptionController.text,
    ));
    isSaving.value = false;
    return result.fold(
      (failure) {
        if (failure is InvalidCatalogDataFailure) {
          AppSnackbar.warning(failure.message, title: 'Revisa el formulario');
        } else {
          AppSnackbar.error(CatalogAccess.messageFor(failure));
        }
        return false;
      },
      (_) {
        Get.back(result: true);
        AppSnackbar.success('Categoría creada');
        return true;
      },
    );
  }
}
