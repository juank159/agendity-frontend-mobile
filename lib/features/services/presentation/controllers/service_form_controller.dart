import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/features/services/domain/entities/category.dart';
import 'package:login_signup/features/services/domain/entities/service_entity.dart';
import 'package:login_signup/features/services/domain/entities/service_price_type.dart';
import 'package:login_signup/features/services/domain/failures/services_failures.dart';
import 'package:login_signup/features/services/domain/usecases/get_categories_usecase.dart';
import 'package:login_signup/features/services/presentation/controllers/catalog_access.dart';
import 'package:login_signup/features/services/presentation/widgets/color_picker.dart';
import 'package:login_signup/shared/utils/color_hex.dart';
import 'package:login_signup/shared/widgets/app_snackbar.dart';

/// Estado y reglas comunes del formulario de servicio (alta y edición; solo
/// Owner: las rutas llevan `RoleMiddleware.ownerOnly()`).
///
/// Las reglas del dato (nombre, precio, duración, categoría, color) las
/// valida el use case (`InvalidCatalogDataFailure`); aquí solo se convierte
/// lo que escribe el usuario.
abstract class ServiceFormController extends GetxController {
  final GetCategoriesUseCase _getCategories;

  ServiceFormController({required GetCategoriesUseCase getCategoriesUseCase})
      : _getCategories = getCategoriesUseCase;

  final nameController = TextEditingController();
  final priceController = TextEditingController();
  final descriptionController = TextEditingController();

  final priceType = ServicePriceType.fixed.obs;
  final duration = const Duration(minutes: 30).obs;
  final selectedCategory = Rxn<CategoryEntity>();
  final color = servicePalette.first.obs;
  /// Visible en el link público de reservas (9.01). Nace apagado, como en
  /// el backend (7.04-9).
  final onlineBooking = false.obs;

  /// Abono mínimo en porcentaje (0–100).
  final deposit = 0.0.obs;

  final categories = <CategoryEntity>[].obs;
  final isSaving = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadCategories();
  }

  @override
  void onClose() {
    nameController.dispose();
    priceController.dispose();
    descriptionController.dispose();
    super.onClose();
  }

  /// Carga las categorías del negocio. `false` si falló (ya avisado).
  Future<bool> loadCategories() async {
    final result = await _getCategories(NoParams());
    return result.fold(
      (failure) {
        AppSnackbar.error(CatalogAccess.messageFor(failure));
        return false;
      },
      (loaded) {
        categories.assignAll(loaded);
        onCategoriesLoaded(loaded);
        return true;
      },
    );
  }

  /// Ajusta la categoría elegida tras cargar la lista.
  @protected
  void onCategoriesLoaded(List<CategoryEntity> loaded);

  /// Categorías para el selector; las vuelve a pedir si aún no hay.
  /// Lista vacía = no hay ninguna (ya avisado).
  Future<List<CategoryEntity>> categoriesForPicker() async {
    if (categories.isEmpty && !await loadCategories()) return const [];
    if (categories.isEmpty) {
      AppSnackbar.warning('Primero crea una categoría para tus servicios.');
    }
    return categories;
  }

  /// Precio escrito (acepta coma decimal y separadores de miles con punto
  /// solo si no hay decimales). `null` si no es un número.
  double? get parsedPrice {
    final text = priceController.text.trim().replaceAll(' ', '');
    if (text.isEmpty) return null;
    final normalized = text.contains(',')
        ? text.replaceAll('.', '').replaceAll(',', '.')
        : text;
    return double.tryParse(normalized);
  }

  /// Entidad con lo que hay en el formulario, o `null` si el precio no es un
  /// número (ya avisado).
  @protected
  ServiceEntity? buildService({String? id}) {
    final price = parsedPrice;
    if (price == null) {
      AppSnackbar.warning('Escribe el precio del servicio (solo números).');
      return null;
    }
    final category = selectedCategory.value;
    return ServiceEntity(
      id: id,
      name: nameController.text,
      description: descriptionController.text,
      price: price,
      priceType: priceType.value,
      duration: duration.value.inMinutes,
      categoryId: category?.id ?? '',
      category: category,
      color: colorToHex(color.value),
      onlineBooking: onlineBooking.value,
      deposit: deposit.value.round(),
    );
  }

  /// Avisa de un fallo al guardar.
  @protected
  void showFailure(Failure failure) {
    if (failure is InvalidCatalogDataFailure) {
      AppSnackbar.warning(failure.message, title: 'Revisa el formulario');
    } else {
      AppSnackbar.error(CatalogAccess.messageFor(failure));
    }
  }

  /// Guarda el formulario. `true` si se guardó.
  Future<bool> save();
}
