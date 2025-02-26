import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/features/services/presentation/widgets/edit_category_dialog.dart';
import 'package:login_signup/features/services/presentation/widgets/status_confirmation_dialog.dart';
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
    debugPrint('CategoriesController inicializado');
    loadCategories(); // Esta línea es crucial
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
      debugPrint('Cargando categorías...');

      final result = await getCategoriesUseCase.execute();
      categories.assignAll(result);

      debugPrint('Categorías cargadas: ${categories.length}');
    } catch (e) {
      debugPrint('Error cargando categorías: $e');
      _showError('No se pudieron cargar las categorías');
    } finally {
      isLoading.value = false;
    }
  }

  void editCategory(CategoryEntity category) {
    debugPrint('Mostrando diálogo para editar categoría: ${category.id}');

    // Cerrar cualquier diálogo anterior si estuviera abierto
    if (Get.isDialogOpen ?? false) {
      Get.back();
    }

    // Mostrar el nuevo diálogo
    Get.dialog(
      // Usar el diálogo modal mejorado
      EditCategoryDialog(
        category: category,
        onSuccess: () {
          debugPrint('Categoría actualizada, recargando lista');
          // Asegurar que esto se ejecute después de que el diálogo se cierre
          Future.delayed(Duration.zero, () {
            loadCategories();
          });
        },
      ),
      barrierDismissible: false, // El usuario debe usar los botones para cerrar
    ).then((_) {
      // Este callback se ejecuta cuando el diálogo se cierra
      debugPrint('Diálogo cerrado');
    });
  }

  // Future<void> toggleCategoryStatus(String id, bool isActive) async {
  //   try {
  //     debugPrint('Cambiando estado de categoría $id a $isActive');
  //     await updateCategoryStatusUseCase.execute(id, isActive);
  //     await loadCategories();
  //   } catch (e) {
  //     debugPrint('Error actualizando estado de categoría: $e');
  //     _showError('No se pudo actualizar el estado de la categoría');
  //   }
  // }

  Future<void> toggleCategoryStatus(String id, bool newStatus) async {
    try {
      // Encontrar la categoría por ID
      final category = categories.firstWhere((cat) => cat.id == id);

      // Mostrar diálogo de confirmación
      Get.dialog(
        StatusConfirmationDialog(
          categoryName: category.name,
          newStatus: newStatus,
          onConfirm: () async {
            try {
              // En lugar de usar snackbar con dismiss, usamos dialog
              Get.dialog(
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 15),
                        Text(
                          newStatus
                              ? 'Activando categoría...'
                              : 'Desactivando categoría...',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
                barrierDismissible: false,
              );

              debugPrint('Cambiando estado de categoría $id a $newStatus');
              await updateCategoryStatusUseCase.execute(id, newStatus);

              // Cerrar el diálogo de carga
              if (Get.isDialogOpen ?? false) {
                Get.back();
              }

              // Mostrar mensaje de éxito
              _showSuccess(newStatus
                  ? 'Categoría activada correctamente'
                  : 'Categoría desactivada correctamente');

              // Recargar categorías para reflejar el cambio
              await loadCategories();
            } catch (e) {
              // Cerrar el diálogo de carga en caso de error también
              if (Get.isDialogOpen ?? false) {
                Get.back();
              }

              debugPrint('Error actualizando estado de categoría: $e');
              _showError('No se pudo actualizar el estado de la categoría');
            }
          },
        ),
        barrierDismissible: false,
      );
    } catch (e) {
      debugPrint('Error al preparar cambio de estado: $e');
      _showError('No se pudo encontrar la categoría');
    }
  }

  // Método para mostrar indicador de carga
  GetSnackBar _showLoading(String message) {
    final loadingSnackbar = GetSnackBar(
      title: 'Procesando',
      message: message,
      isDismissible: false,
      duration: const Duration(seconds: 100),
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.blue,
      icon: const CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
      ),
    );

    loadingSnackbar.show();
    return loadingSnackbar;
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

  void _showSuccess(String message) {
    Get.snackbar(
      'Éxito',
      message,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(8),
      borderRadius: 8,
    );
  }

  void refreshAfterCreate() {
    debugPrint('Refrescando categorías después de crear una nueva');
    loadCategories();
  }
}
