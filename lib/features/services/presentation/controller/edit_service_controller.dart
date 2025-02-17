import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/features/services/domain/entities/category.dart';
import 'package:login_signup/features/services/domain/entities/service_entity.dart';
import 'package:login_signup/features/services/domain/usecases/delete_service_usecase.dart';
import 'package:login_signup/features/services/domain/usecases/update_service_usecase.dart';
import 'package:login_signup/features/services/presentation/controller/categories_controller.dart';
import 'package:login_signup/features/services/presentation/controller/services_controller.dart';
import 'package:login_signup/features/services/presentation/widgets/category_picker.dart';
import 'package:login_signup/features/services/presentation/widgets/duration_picker.dart';

class EditServiceController extends GetxController {
  final UpdateServiceUseCase updateServiceUseCase;
  final DeleteServiceUseCase deleteServiceUseCase;
  final ServiceEntity service;

  final nameController = TextEditingController();
  final priceController = TextEditingController();
  final descriptionController = TextEditingController();
  final price = 0.0.obs;
  final duration = const Duration(minutes: 30).obs;
  final selectedPriceType = 'Precio fijo'.obs;
  final selectedTab = 0.obs;
  final isLoading = false.obs;
  final isOnlineBooking = true.obs;
  final selectedCategory = Rxn<CategoryEntity>();
  final minimumDeposit = 0.0.obs;
  final depositType = 'percentage'.obs;

  final priceTypes = ['Precio fijo', 'Precio variable'];

  final selectedColor = MaterialColor(
    Colors.blue.value,
    const <int, Color>{
      50: Colors.blue,
      100: Colors.blue,
      200: Colors.blue,
      300: Colors.blue,
      400: Colors.blue,
      500: Colors.blue,
      600: Colors.blue,
      700: Colors.blue,
      800: Colors.blue,
      900: Colors.blue,
    },
  ).obs;

  final List<MaterialColor> availableColors = [
    Colors.blue,
    Colors.green,
    Colors.pink,
    Colors.teal,
    Colors.amber,
    Colors.indigo,
    Colors.cyan,
    Colors.grey,
    Colors.deepPurple,
    Colors.lime,
    Colors.brown,
    Colors.yellow,
  ]
      .map((color) => MaterialColor(
            color.value,
            <int, Color>{
              50: color,
              100: color,
              200: color,
              300: color,
              400: color,
              500: color,
              600: color,
              700: color,
              800: color,
              900: color,
            },
          ))
      .toList();

  EditServiceController({
    required this.updateServiceUseCase,
    required this.deleteServiceUseCase,
    required this.service,
  });

  @override
  void onInit() {
    super.onInit();
    _initializeData();
    priceController.addListener(_updatePrice);
  }

  void _initializeData() {
    nameController.text = service.name;
    priceController.text = service.price.toString();
    descriptionController.text = service.description;
    duration.value = Duration(minutes: service.duration);
    selectedPriceType.value = service.priceType;
    isOnlineBooking.value = service.onlineBooking;
    selectedCategory.value = service.category;
    minimumDeposit.value = service.deposit.toDouble();
    selectedColor.value = _getColorFromHex(service.color);
  }

  void selectTab(int index) {
    selectedTab.value = index;
  }

  void _updatePrice() {
    if (priceController.text.isNotEmpty) {
      price.value = double.tryParse(priceController.text) ?? 0.0;
    } else {
      price.value = 0.0;
    }
  }

  MaterialColor _getColorFromHex(String colorHex) {
    try {
      final color =
          Color(int.parse(colorHex.replaceFirst('#', 'FF'), radix: 16));
      return MaterialColor(
        color.value,
        <int, Color>{
          50: color,
          100: color,
          200: color,
          300: color,
          400: color,
          500: color,
          600: color,
          700: color,
          800: color,
          900: color,
        },
      );
    } catch (e) {
      return Colors.blue;
    }
  }

  void selectPriceType() {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Tipo de precio',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ...priceTypes.map((type) => _buildPriceTypeOption(type)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: const Text('CANCELAR'),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => Get.back(),
                    child: const Text('ACEPTAR'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriceTypeOption(String type) {
    return ListTile(
      title: Text(type),
      trailing: Obx(() => selectedPriceType.value == type
          ? const Icon(Icons.check, color: Colors.deepPurple)
          : const SizedBox.shrink()),
      onTap: () => selectedPriceType.value = type,
    );
  }

  void showDurationPicker() {
    Get.dialog(
      DurationPicker(
        duration: duration,
        onChanged: (newDuration) => duration.value = newDuration,
      ),
    );
  }

  void selectCategory() async {
    try {
      if (!Get.isRegistered<CategoriesController>()) {
        await Get.putAsync(() async => CategoriesController(
              getCategoriesUseCase: Get.find(),
              updateCategoryStatusUseCase: Get.find(),
            ));
        await Get.find<CategoriesController>().loadCategories();
      }

      final categories = Get.find<CategoriesController>().categories;

      if (categories.isEmpty) {
        _showError('No hay categorías disponibles');
        return;
      }

      Get.dialog(
        CategoryPicker(
          categories: categories,
          selectedCategory: selectedCategory,
          onChanged: (category) {
            selectedCategory.value = category;
          },
        ),
      );
    } catch (e) {
      _showError('Error al cargar las categorías');
    }
  }

  void setDepositType(String type) {
    depositType.value = type;
  }

  Future<void> updateService() async {
    print('Service ID: ${service.id}');
    print('Original Category ID: ${service.categoryId}');
    print('Selected Category ID: ${selectedCategory.value?.id}');
    print('Selected Category Name: ${selectedCategory.value?.name}');

    if (!_validateForm()) return;

    try {
      isLoading.value = true;

      if (service.id == null) {
        throw Exception('Service ID is null');
      }

      final updatedService = ServiceEntity(
        name: nameController.text.trim(),
        description: descriptionController.text.trim(),
        price: double.parse(priceController.text),
        priceType: selectedPriceType.value,
        duration: duration.value.inMinutes,
        categoryId:
            selectedCategory.value!.id, // Forzamos el uso de la nueva categoría
        color: '#${selectedColor.value.value.toRadixString(16).substring(2)}',
        onlineBooking: isOnlineBooking.value,
        deposit: minimumDeposit.value.round(),
      );

      print('Updated Service Data: ${updatedService.toJson()}');

      await updateServiceUseCase.execute(service.id!, updatedService);
      await Get.find<ServicesController>().refreshServices();
      Get.back();
      _showSuccess('Servicio actualizado correctamente');
    } catch (e) {
      print('Error updating service: $e');
      _showError('Error al actualizar el servicio: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteService() async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: const Text('¿Estás seguro de eliminar este servicio?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await deleteServiceUseCase.execute(service.id!);
        await Get.find<ServicesController>().refreshServices();
        Get.back();
        _showSuccess('Servicio eliminado correctamente');
      } catch (e) {
        _showError('Error al eliminar el servicio');
      }
    }
  }

  bool _validateForm() {
    if (nameController.text.trim().isEmpty) {
      _showError('El nombre del servicio es requerido');
      return false;
    }

    if (double.parse(priceController.text) <= 0) {
      _showError('El precio debe ser mayor a 0');
      return false;
    }

    if (selectedCategory.value == null) {
      _showError('Debe seleccionar una categoría');
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

  @override
  void onClose() {
    nameController.dispose();
    priceController.dispose();
    descriptionController.dispose();
    super.onClose();
  }
}
