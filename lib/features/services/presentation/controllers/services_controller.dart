import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/routes/routes.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/features/services/domain/entities/service_entity.dart';
import 'package:login_signup/features/services/domain/usecases/get_categories_usecase.dart';
import 'package:login_signup/features/services/domain/usecases/get_services_usecase.dart';
import 'package:login_signup/features/services/presentation/controllers/catalog_access.dart';
import 'package:login_signup/shared/widgets/app_dialogs.dart';
import 'package:login_signup/shared/widgets/app_snackbar.dart';

/// Lista de servicios del negocio. El Owner la gestiona; el Employee la ve en
/// solo lectura ([canManage]).
///
/// Registro único: `ServicesBinding.registerController()` (lo llaman la ruta
/// de servicios y las de empleados, que también listan servicios). Lo borra
/// `SessionScope` al cerrar sesión.
class ServicesController extends GetxController {
  final GetServicesUseCase _getServices;
  final GetCategoriesUseCase _getCategories;

  ServicesController({
    required GetServicesUseCase getServicesUseCase,
    required GetCategoriesUseCase getCategoriesUseCase,
  })  : _getServices = getServicesUseCase,
        _getCategories = getCategoriesUseCase;

  final services = <ServiceEntity>[].obs;
  final isLoading = false.obs;

  /// Error de la última carga (`null` si fue bien).
  final loadError = RxnString();

  Future<void>? _inFlight;

  bool get canManage => CatalogAccess.canManage();

  @override
  void onInit() {
    super.onInit();
    loadServices();
  }

  /// Carga la lista. Si ya hay una carga en curso, devuelve esa.
  Future<void> loadServices() =>
      _inFlight ??= _load().whenComplete(() => _inFlight = null);

  Future<void> _load() async {
    isLoading.value = true;
    loadError.value = null;
    final result = await _getServices(NoParams());
    isLoading.value = false;
    result.fold(
      (failure) {
        final message = CatalogAccess.messageFor(failure);
        loadError.value = message;
        if (services.isNotEmpty) AppSnackbar.error(message);
      },
      services.assignAll,
    );
  }

  /// Servicios agrupados por el nombre de su categoría.
  Map<String, List<ServiceEntity>> getServicesGroupedByCategory() {
    final grouped = <String, List<ServiceEntity>>{};
    for (final service in services) {
      final name = service.category?.name ?? 'Sin categoría';
      grouped.putIfAbsent(name, () => []).add(service);
    }
    return grouped;
  }

  /// Alta de un servicio. Sin categorías, ofrece ir a crearlas primero.
  Future<void> openNewService() async {
    if (!canManage) return;
    final result = await _getCategories(NoParams());
    final hasCategories = result.fold(
      (failure) {
        AppSnackbar.error(CatalogAccess.messageFor(failure));
        return null;
      },
      (categories) => categories.isNotEmpty,
    );
    if (hasCategories == null) return;
    if (!hasCategories) {
      final goToCategories = await AppDialogs.confirm(
        title: 'Primero crea una categoría',
        message: 'Cada servicio pertenece a una categoría. '
            '¿Quieres ir a crear una?',
        confirmLabel: 'Ir a categorías',
        icon: Icons.folder_outlined,
      );
      if (goToCategories) await openCategories();
      return;
    }
    final created = await Get.toNamed(GetRoutes.addService);
    if (created == true) await loadServices();
  }

  Future<void> openEditService(ServiceEntity service) async {
    if (!canManage) return;
    final changed =
        await Get.toNamed(GetRoutes.editService, arguments: service);
    if (changed == true) await loadServices();
  }

  /// Categorías (el Employee las ve en solo lectura). Al volver se recarga:
  /// un cambio de nombre cambia los grupos.
  Future<void> openCategories() async {
    await Get.toNamed(GetRoutes.categories);
    await loadServices();
  }
}
