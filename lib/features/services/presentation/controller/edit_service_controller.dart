import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/features/services/domain/entities/category.dart';
import 'package:login_signup/features/services/domain/entities/service_entity.dart';
import 'package:login_signup/features/services/domain/usecases/delete_service_usecase.dart';
import 'package:login_signup/features/services/domain/usecases/update_service_usecase.dart';
import 'package:login_signup/features/services/presentation/controller/catalog_access.dart';
import 'package:login_signup/features/services/presentation/controller/service_form_controller.dart';
import 'package:login_signup/features/services/presentation/widgets/color_picker.dart';
import 'package:login_signup/shared/widgets/app_dialogs.dart';
import 'package:login_signup/shared/widgets/app_snackbar.dart';

/// Edición y borrado de un servicio. Al guardar o borrar vuelve a la lista
/// con `result: true`.
class EditServiceController extends ServiceFormController {
  final UpdateServiceUseCase _updateService;
  final DeleteServiceUseCase _deleteService;
  final ServiceEntity service;

  EditServiceController({
    required super.getCategoriesUseCase,
    required UpdateServiceUseCase updateServiceUseCase,
    required DeleteServiceUseCase deleteServiceUseCase,
    required this.service,
  })  : _updateService = updateServiceUseCase,
        _deleteService = deleteServiceUseCase;

  final isDeleting = false.obs;

  @override
  void onInit() {
    nameController.text = service.name;
    priceController.text = _priceText(service.price);
    descriptionController.text = service.description;
    priceType.value = service.priceType;
    duration.value = Duration(minutes: service.duration);
    selectedCategory.value = service.category;
    color.value = colorFromHex(service.color);
    onlineBooking.value = service.onlineBooking;
    deposit.value = service.deposit.clamp(0, 100).toDouble();
    super.onInit();
  }

  @override
  void onCategoriesLoaded(List<CategoryEntity> loaded) {
    final current = loaded.firstWhereOrNull((c) => c.id == service.categoryId);
    if (current != null) selectedCategory.value = current;
  }

  @override
  Future<bool> save() async {
    if (isSaving.value || isDeleting.value) return false;
    final updated = buildService(id: service.id);
    if (updated == null) return false;

    isSaving.value = true;
    final result = await _updateService(updated);
    isSaving.value = false;
    return result.fold(
      (failure) {
        showFailure(failure);
        return false;
      },
      (_) {
        Get.back(result: true);
        AppSnackbar.success('Servicio actualizado');
        return true;
      },
    );
  }

  /// Pide confirmación y borra el servicio. `true` si se borró.
  Future<bool> delete() async {
    final id = service.id;
    if (id == null || isSaving.value || isDeleting.value) return false;
    final confirmed = await AppDialogs.confirm(
      title: '¿Eliminar servicio?',
      message: 'Se eliminará "${service.name}" del catálogo.',
      confirmLabel: 'Eliminar',
      destructive: true,
      icon: Icons.delete_outline,
    );
    if (!confirmed) return false;

    isDeleting.value = true;
    final result = await _deleteService(id);
    isDeleting.value = false;
    return result.fold(
      (failure) {
        AppSnackbar.error(CatalogAccess.messageFor(failure));
        return false;
      },
      (_) {
        Get.back(result: true);
        AppSnackbar.success('Servicio eliminado');
        return true;
      },
    );
  }

  /// `45000.0` → `45000`; `45000.5` → `45000.5`.
  static String _priceText(double price) => price == price.roundToDouble()
      ? price.toStringAsFixed(0)
      : price.toString();
}
