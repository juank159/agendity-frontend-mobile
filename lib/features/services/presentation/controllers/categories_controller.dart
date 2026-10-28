import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/routes/routes.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/features/services/domain/entities/category.dart';
import 'package:login_signup/features/services/domain/failures/services_failures.dart';
import 'package:login_signup/features/services/domain/usecases/delete_category_usecase.dart';
import 'package:login_signup/features/services/domain/usecases/get_categories_usecase.dart';
import 'package:login_signup/features/services/domain/usecases/update_category_status_usecase.dart';
import 'package:login_signup/features/services/domain/usecases/update_category_usecase.dart';
import 'package:login_signup/features/services/presentation/controllers/catalog_access.dart';
import 'package:login_signup/features/services/presentation/widgets/edit_category_dialog.dart';
import 'package:login_signup/shared/widgets/app_dialogs.dart';
import 'package:login_signup/shared/widgets/app_snackbar.dart';

/// Categorías del negocio: lista y acciones del Owner (crear, renombrar,
/// activar/desactivar y borrar). El Employee las ve en solo lectura
/// ([canManage]).
class CategoriesController extends GetxController {
  final GetCategoriesUseCase _getCategories;
  final UpdateCategoryUseCase _updateCategory;
  final UpdateCategoryStatusUseCase _updateStatus;
  final DeleteCategoryUseCase _deleteCategory;

  CategoriesController({
    required GetCategoriesUseCase getCategoriesUseCase,
    required UpdateCategoryUseCase updateCategoryUseCase,
    required UpdateCategoryStatusUseCase updateCategoryStatusUseCase,
    required DeleteCategoryUseCase deleteCategoryUseCase,
  })  : _getCategories = getCategoriesUseCase,
        _updateCategory = updateCategoryUseCase,
        _updateStatus = updateCategoryStatusUseCase,
        _deleteCategory = deleteCategoryUseCase;

  final categories = <CategoryEntity>[].obs;
  final isLoading = false.obs;
  final loadError = RxnString();

  /// Una acción en curso (bloquea las demás).
  final isBusy = false.obs;

  bool get canManage => CatalogAccess.canManage();

  @override
  void onInit() {
    super.onInit();
    loadCategories();
  }

  Future<void> loadCategories() async {
    isLoading.value = true;
    loadError.value = null;
    final result = await _getCategories(NoParams());
    isLoading.value = false;
    result.fold(
      (failure) {
        final message = CatalogAccess.messageFor(failure);
        loadError.value = message;
        if (categories.isNotEmpty) AppSnackbar.error(message);
      },
      categories.assignAll,
    );
  }

  Future<void> openNewCategory() async {
    if (!canManage) return;
    final created = await Get.toNamed(GetRoutes.addCategory);
    if (created == true) await loadCategories();
  }

  Future<void> editCategory(CategoryEntity category) async {
    if (!canManage) return;
    await EditCategoryDialog.show(
      category: category,
      onSave: (name, description) =>
          updateCategory(category, name: name, description: description),
    );
  }

  /// Renombra o cambia la descripción. `true` si se guardó.
  Future<bool> updateCategory(
    CategoryEntity category, {
    required String name,
    required String description,
  }) async {
    if (!canManage || isBusy.value) return false;
    isBusy.value = true;
    final result = await _updateCategory(UpdateCategoryParams(
        id: category.id, name: name, description: description));
    isBusy.value = false;
    return result.fold(
      (failure) {
        AppSnackbar.error(CatalogAccess.messageFor(failure));
        return false;
      },
      (updated) {
        _replace(category, updated);
        AppSnackbar.success('Categoría actualizada');
        return true;
      },
    );
  }

  /// Activa o desactiva, con confirmación.
  Future<void> setActive(CategoryEntity category, bool active) async {
    if (!canManage || isBusy.value) return;
    final confirmed = await AppDialogs.confirm(
      title: active ? '¿Activar categoría?' : '¿Desactivar categoría?',
      message: active
          ? 'Los servicios de "${category.name}" volverán a estar disponibles.'
          : 'Se ocultarán también los servicios de "${category.name}".',
      confirmLabel: active ? 'Activar' : 'Desactivar',
      destructive: !active,
      icon: active ? Icons.check_circle_outline : Icons.visibility_off_outlined,
    );
    if (!confirmed) return;

    isBusy.value = true;
    final result = await _updateStatus(
        UpdateCategoryStatusParams(id: category.id, isActive: active));
    isBusy.value = false;
    result.fold(
      (failure) => AppSnackbar.error(CatalogAccess.messageFor(failure)),
      (updated) {
        _replace(category, updated);
        AppSnackbar.success(
            active ? 'Categoría activada' : 'Categoría desactivada');
      },
    );
  }

  /// Borra con confirmación. Una categoría con servicios no se puede borrar
  /// (regla de negocio): si ya se sabe que tiene, se avisa sin llamar al
  /// backend; si no, lo dice el `CategoryHasServicesFailure`.
  Future<void> deleteCategory(CategoryEntity category) async {
    if (!canManage || isBusy.value) return;
    if (category.hasServices) {
      await _showHasServices();
      return;
    }
    final confirmed = await AppDialogs.confirm(
      title: '¿Eliminar categoría?',
      message: 'Se eliminará "${category.name}". Esta acción no se puede '
          'deshacer.',
      confirmLabel: 'Eliminar',
      destructive: true,
    );
    if (!confirmed) return;

    isBusy.value = true;
    final result = await _deleteCategory(category.id);
    isBusy.value = false;
    final failure = result.fold((f) => f, (_) => null);
    if (failure is CategoryHasServicesFailure) {
      await _showHasServices();
    } else if (failure != null) {
      AppSnackbar.error(CatalogAccess.messageFor(failure));
    } else {
      categories.removeWhere((c) => c.id == category.id);
      AppSnackbar.success('Categoría eliminada');
    }
  }

  Future<void> _showHasServices() => AppDialogs.error(
        title: 'No se puede eliminar',
        message: CatalogAccess.categoryHasServicesMessage,
      );

  /// Sustituye [old] por [updated] conservando el número de servicios si la
  /// respuesta no lo trae.
  void _replace(CategoryEntity old, CategoryEntity updated) {
    final index = categories.indexWhere((c) => c.id == old.id);
    if (index < 0) return;
    categories[index] = updated.serviceCount == null
        ? updated.copyWith(serviceCount: old.serviceCount)
        : updated;
  }
}
