import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/features/services/presentation/controller/categories_controller.dart';
import '../../domain/entities/category.dart';
import '../../domain/usecases/update_category_usecase.dart';

class EditCategoryController extends GetxController {
  final UpdateCategoryUseCase updateCategoryUseCase;

  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final RxBool isLoading = false.obs;

  late String categoryId;

  EditCategoryController({required this.updateCategoryUseCase});

  @override
  void onInit() {
    super.onInit();
    // Obtenemos los datos de la categoría que se pasó como argumento
    if (Get.arguments != null && Get.arguments is CategoryEntity) {
      final category = Get.arguments as CategoryEntity;
      categoryId = category.id;
      nameController.text = category.name;
      descriptionController.text = category.description;
    }
  }

  @override
  void onClose() {
    nameController.dispose();
    descriptionController.dispose();
    super.onClose();
  }

  Future<void> updateCategory() async {
    if (!_validateForm()) return;

    try {
      isLoading.value = true;

      await updateCategoryUseCase.execute(
        categoryId,
        nameController.text.trim(),
        descriptionController.text.trim(),
      );

      _showSuccess('Categoría actualizada correctamente');

      // Navegamos de vuelta
      Get.back();

      // Refrescamos la lista de categorías si el controlador existe
      try {
        if (Get.isRegistered<CategoriesController>()) {
          final categoriesController = Get.find<CategoriesController>();
          categoriesController.loadCategories();
        }
      } catch (e) {
        debugPrint('Error al refrescar categorías: $e');
      }
    } catch (e) {
      _showError('No se pudo actualizar la categoría');
    } finally {
      isLoading.value = false;
    }
  }

  bool _validateForm() {
    if (nameController.text.trim().isEmpty) {
      _showError('El nombre de la categoría es requerido');
      return false;
    }
    return true;
  }

  void _showSuccess(String message) {
    Get.snackbar(
      'Éxito',
      message,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
    );
  }

  void _showError(String message) {
    Get.snackbar(
      'Error',
      message,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
    );
  }
}
