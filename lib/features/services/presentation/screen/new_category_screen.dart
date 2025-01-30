// lib/features/categories/presentation/screens/new_category_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/features/services/presentation/controller/new_category_controller.dart';

class NewCategoryScreen extends GetView<NewCategoryController> {
  const NewCategoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Añadir categoría de servicio',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: controller.nameController,
              decoration: InputDecoration(
                labelText: 'Nombre de la categoría',
                hintText: 'Ejemplo: Spa de uñas, Barbería, Cortes clásicos...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                ),
                prefixIcon: const Icon(Icons.category),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller.descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Descripción',
                hintText:
                    'Describe los servicios que se incluyen en esta categoría',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                ),
                prefixIcon: const Icon(Icons.description),
              ),
            ),
            const SizedBox(height: 24),
            Obx(() => ElevatedButton(
                  onPressed: controller.isLoading.value
                      ? null
                      : controller.saveCategory,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: controller.isLoading.value
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Guardar cambios',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                )),
          ],
        ),
      ),
    );
  }
}
