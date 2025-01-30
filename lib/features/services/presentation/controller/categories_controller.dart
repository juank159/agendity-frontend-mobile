import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../domain/entities/category.dart';
import '../../domain/usecases/get_categories_usecase.dart';
import '../../domain/usecases/update_category_status_usecase.dart';

class CategoriesController extends GetxController {
  final GetCategoriesUseCase getCategoriesUseCase;
  final UpdateCategoryStatusUseCase updateCategoryStatusUseCase;

  final RxList<CategoryEntity> categories = <CategoryEntity>[].obs;
  final RxBool isLoading = true.obs;

  CategoriesController({
    required this.getCategoriesUseCase,
    required this.updateCategoryStatusUseCase,
  });

  @override
  void onInit() {
    super.onInit();
    loadCategories();
  }

  @override
  void onClose() {
    categories.clear();
    isLoading.value = true;
    super.onClose();
  }

  Future<void> loadCategories() async {
    try {
      isLoading.value = true;
      final result = await getCategoriesUseCase.execute();
      categories.assignAll(result);
      print('Categorías cargadas: ${categories.length}');
    } catch (e) {
      print('Error cargando categorías: $e');
      _showError('No se pudieron cargar las categorías');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> toggleCategoryStatus(String id, bool isActive) async {
    try {
      await updateCategoryStatusUseCase.execute(id, isActive);
      await loadCategories();
    } catch (e) {
      print('Error actualizando estado de categoría: $e');
      _showError('No se pudo actualizar el estado de la categoría');
    }
  }

  void _showError(String message) {
    Get.snackbar(
      'Error',
      message,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(8),
      borderRadius: 8,
    );
  }

  void refreshCategories() {
    loadCategories();
  }
}
