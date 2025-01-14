import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/features/services/domain/entities/category.dart';
import 'package:login_signup/features/services/domain/usecases/get_categories_usecase.dart';
import 'package:login_signup/features/services/presentation/widgets/category_picker.dart';

import '../widgets/duration_picker.dart';

class NewServiceController extends GetxController {
  final GetCategoriesUseCase getCategoriesUseCase;

  // Controllers para los campos de texto
  final nameController = TextEditingController();
  final priceController = TextEditingController();
  final descriptionController = TextEditingController();

  // Observables básicos
  final price = 0.0.obs;
  final duration = const Duration(minutes: 30).obs;
  final selectedPriceType = 'Precio fijo'.obs;
  final isLoading = false.obs;
  final selectedTab = 0.obs;

  // Observables de configuración adicional
  final isOnlineBooking = true.obs;
  final showServiceTime = false.obs;
  final categories = <Category>[].obs;
  final selectedCategory = Rxn<Category>();
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
  final minimumDeposit = 0.0.obs;
  final depositType = 'percentage'.obs;

  // Listas y constantes
  final priceTypes = ['Precio fijo', 'Precio variable'];
  final List<MaterialColor> availableColors = [
    _createMaterialColor(Colors.blue),
    _createMaterialColor(Colors.green),
    _createMaterialColor(Colors.orange),
    _createMaterialColor(Colors.teal),
    _createMaterialColor(Colors.amber),
    _createMaterialColor(Colors.indigo),
    _createMaterialColor(Colors.cyan),
    _createMaterialColor(Colors.grey),
    _createMaterialColor(Colors.deepPurple),
    _createMaterialColor(Colors.lime),
    _createMaterialColor(Colors.brown),
    _createMaterialColor(Colors.yellow),
  ];

  NewServiceController({required this.getCategoriesUseCase});

  static MaterialColor _createMaterialColor(Color color) {
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
  }

  @override
  void onInit() {
    super.onInit();
    loadCategories();
    priceController.addListener(_updatePrice);
  }

  @override
  void onClose() {
    nameController.dispose();
    priceController.dispose();
    descriptionController.dispose();
    super.onClose();
  }

  Future<void> loadCategories() async {
    try {
      final result = await getCategoriesUseCase.execute();
      categories.value = result;
      // Ya no seleccionamos una categoría por defecto
      selectedCategory.value = null;
    } catch (e) {
      _showError('Error al cargar las categorías');
    }
  }

  void _updatePrice() {
    if (priceController.text.isNotEmpty) {
      price.value = double.tryParse(priceController.text) ?? 0.0;
    } else {
      price.value = 0.0;
    }
  }

  void selectTab(int index) {
    selectedTab.value = index;
  }

  void selectColor(MaterialColor color) {
    selectedColor.value = color;
  }

  void showDurationPicker() {
    Get.dialog(
      DurationPicker(
        duration: duration,
        onChanged: (newDuration) => duration.value = newDuration,
      ),
      barrierColor: Colors.black.withOpacity(0.3),
    );
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
      barrierColor: Colors.black.withOpacity(0.3),
    );
  }

  void selectCategory() {
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
      barrierColor: Colors.black.withOpacity(0.3),
    );
  }

  void setDepositType(String type) {
    depositType.value = type;
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

  Future<void> saveService() async {
    if (!_validateForm()) return;

    try {
      isLoading.value = true;
      await _saveServiceToApi();
      _showSuccess('Servicio creado correctamente');
      Get.back(result: _createServiceData());
    } catch (e) {
      _showError('No se pudo crear el servicio');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _saveServiceToApi() async {
    await Future.delayed(const Duration(seconds: 1));
  }

  Map<String, dynamic> _createServiceData() {
    return {
      'name': nameController.text.trim(),
      'price': price.value,
      'priceType': selectedPriceType.value,
      'duration': duration.value.inMinutes,
      'description': descriptionController.text.trim(),
      'isOnlineBooking': isOnlineBooking.value,
      'showServiceTime': showServiceTime.value,
      'categoryId': selectedCategory.value?.id,
      'color': selectedColor.value.shade500.value,
      'depositType': depositType.value,
      'minimumDeposit': minimumDeposit.value,
    };
  }

  bool _validateForm() {
    if (_isEmptyField(nameController.text)) {
      _showError('El nombre del servicio es requerido');
      return false;
    }

    if (_isInvalidPrice()) {
      _showError('El precio debe ser mayor a 0');
      return false;
    }

    if (selectedCategory.value == null) {
      _showError('Debe seleccionar una categoría');
      return false;
    }

    return true;
  }

  bool _isEmptyField(String value) => value.trim().isEmpty;
  bool _isInvalidPrice() => price.value <= 0;

  void _showSuccess(String message) {
    _showSnackbar('Éxito', message, Colors.green);
  }

  void _showError(String message) {
    _showSnackbar('Error', message, Colors.red);
  }

  void _showSnackbar(String title, String message, Color backgroundColor) {
    Get.snackbar(
      title,
      message,
      backgroundColor: backgroundColor,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
      duration: const Duration(seconds: 3),
    );
  }
}
