import 'package:get/get.dart';
import 'package:login_signup/features/services/presentation/controller/categories_controller.dart';
import '../../domain/entities/service_entity.dart';
import '../../domain/usecases/get_services_usecase.dart';

class ServicesController extends GetxController {
  final GetServicesUseCase _getServicesUseCase;

  final RxList<ServiceEntity> services = <ServiceEntity>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool isInitialized = false.obs;

  ServicesController({
    required GetServicesUseCase getServicesUseCase,
  }) : _getServicesUseCase = getServicesUseCase;

  @override
  void onInit() {
    print('ServicesController: Inicializado');
    super.onInit();
  }

  Future<bool> initializeServices() async {
    if (!isInitialized.value) {
      await loadServices();
      isInitialized.value = true;
    }
    return true;
  }

  Future<bool> checkIfCategoriesExist() async {
    try {
      if (!Get.isRegistered<CategoriesController>()) {
        // Si no está registrado el controlador, lo registramos
        Get.put(CategoriesController(
          getCategoriesUseCase: Get.find(),
          updateCategoryStatusUseCase: Get.find(),
        ));
      }

      final categoriesController = Get.find<CategoriesController>();
      await categoriesController.loadCategories();
      return categoriesController.categories.isNotEmpty;
    } catch (e) {
      print('Error verificando categorías: $e');
      return false;
    }
  }

  Future<void> refreshCategories() async {
    try {
      if (Get.isRegistered<CategoriesController>()) {
        final categoriesController = Get.find<CategoriesController>();
        await categoriesController.loadCategories();
      }
    } catch (e) {
      print('Error refrescando categorías: $e');
    }
  }

  Future<void> loadServices() async {
    try {
      isLoading.value = true;
      final result = await _getServicesUseCase.execute();
      services.clear();
      services.assignAll(result);
      print('Servicios cargados: ${services.length}');
    } catch (e) {
      print('Error cargando servicios: $e');
      services.clear();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshServices() async {
    await loadServices();
    if (!isInitialized.value) {
      isInitialized.value = true;
    }
  }

  Map<String, List<ServiceEntity>> getServicesGroupedByCategory() {
    final groupedServices = <String, List<ServiceEntity>>{};

    for (var service in services) {
      print('Service: ${service.name}');
      print('Category ID: ${service.categoryId}');
      print('Category: ${service.category?.name}');
      print('-------------------');

      final categoryName = service.category?.name ?? 'Sin categoría';

      if (!groupedServices.containsKey(categoryName)) {
        groupedServices[categoryName] = [];
      }
      groupedServices[categoryName]!.add(service);
    }

    print('Grouped Services: ${groupedServices.keys.toList()}');
    return groupedServices;
  }

  // Map<String, List<ServiceEntity>> getServicesGroupedByCategory() {
  //   final groupedServices = <String, List<ServiceEntity>>{};

  //   // Obtener categorías únicas primero
  //   final categories = services
  //       .where((s) => s.category != null)
  //       .map((s) => s.category!)
  //       .toSet()
  //       .toList();

  //   // Agrupar servicios por categoría
  //   for (var category in categories) {
  //     final categoryServices =
  //         services.where((s) => s.categoryId == category.id).toList();
  //     groupedServices[category.name] = categoryServices;
  //   }

  //   // Manejar servicios sin categoría
  //   final servicesWithoutCategory =
  //       services.where((s) => s.category == null).toList();
  //   if (servicesWithoutCategory.isNotEmpty) {
  //     groupedServices['Sin categoría'] = servicesWithoutCategory;
  //   }

  //   return groupedServices;
  // }

  // Map<String, List<ServiceEntity>> getServicesGroupedByCategory() {
  //   final groupedServices = <String, List<ServiceEntity>>{};

  //   for (var service in services) {
  //     final categoryName = service.category?.name ?? 'Sin categoría';
  //     if (!groupedServices.containsKey(categoryName)) {
  //       groupedServices[categoryName] = [];
  //     }
  //     groupedServices[categoryName]!.add(service);
  //   }

  //   return groupedServices;
  // }

  void clearServices() {
    services.clear();
    isInitialized.value = false;
    isLoading.value = true;
  }

  @override
  void onClose() {
    print('ServicesController: Cerrando controlador');
    clearServices();
    super.onClose();
  }
}
