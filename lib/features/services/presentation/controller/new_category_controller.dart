import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:login_signup/features/services/domain/entities/category.dart';
import 'package:login_signup/features/services/domain/usecases/create_category_usecase.dart';
import 'package:login_signup/features/services/presentation/controller/categories_controller.dart';

class NewCategoryController extends GetxController {
  final CreateCategoryUseCase createCategoryUseCase;

  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final RxBool isLoading = false.obs;

  NewCategoryController({required this.createCategoryUseCase});

  @override
  void onClose() {
    nameController.dispose();
    descriptionController.dispose();
    super.onClose();
  }

  Future<void> saveCategory() async {
    if (!_validateForm()) return;

    try {
      isLoading.value = true;

      final category = CategoryEntity(
        id: '',
        name: nameController.text.trim(),
        description: descriptionController.text.trim(),
      );

      await createCategoryUseCase.execute(category);

      _showSuccess('Categoría creada correctamente');

      // Primero navegamos de vuelta
      Get.back();

      // Luego intentamos refrescar la lista de categorías si el controlador existe
      try {
        if (Get.isRegistered<CategoriesController>()) {
          final categoriesController = Get.find<CategoriesController>();
          categoriesController
              .loadCategories(); // Usamos loadCategories directamente
        }
      } catch (e) {
        debugPrint('Error al refrescar categorías: $e');
      }
    } catch (e) {
      _showError('No se pudo crear la categoría');
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
