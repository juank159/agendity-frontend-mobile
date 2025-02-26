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
  final RxBool isFormValid = false.obs;

  NewCategoryController({required this.createCategoryUseCase});

  @override
  void onInit() {
    super.onInit();
    debugPrint('NewCategoryController inicializado');
    nameController.addListener(_validateForm);
    descriptionController.addListener(_validateForm);
  }

  @override
  void onClose() {
    nameController.dispose();
    descriptionController.dispose();
    super.onClose();
  }

  void _validateForm() {
    isFormValid.value = nameController.text.trim().isNotEmpty;
  }

  Future<void> saveCategory() async {
    final name = nameController.text.trim();
    final description = descriptionController.text.trim();

    debugPrint('Intentando guardar categoría: "$name", "$description"');

    if (name.isEmpty) {
      showError('El nombre de la categoría es requerido');
      return;
    }

    try {
      isLoading.value = true;

      debugPrint('Creando categoría con nombre: $name');

      final category = CategoryEntity(
        id: '', // El ID lo generará el backend
        name: name,
        description: description,
      );

      await createCategoryUseCase.execute(category);

      debugPrint('Categoría creada exitosamente');

      showSuccess('Categoría creada correctamente');
      if (Get.isRegistered<CategoriesController>()) {
        final categoriesController = Get.find<CategoriesController>();
        categoriesController.refreshAfterCreate();
      }

      // Clave del cambio: usar Get.back() con result para indicar éxito
      Get.offAndToNamed('/categories');
    } catch (e) {
      debugPrint('Error al crear categoría: $e');
      showError('No se pudo crear la categoría: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  void showSuccess(String message) {
    Get.snackbar(
      'Éxito',
      message,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 3),
    );
  }

  void showError(String message) {
    Get.snackbar(
      'Error',
      message,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 3),
    );
  }
}
