import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/categories_controller.dart';

class CategoriesScreen extends GetView<CategoriesController> {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Permitir retroceder sin mostrar un cuadro de diálogo
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Categorías de servicio',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              // Retroceder directamente
              Get.back();
            },
          ),
        ),
        body: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.categories.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.category_outlined,
                      size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No hay categorías',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => Get.toNamed('/categories/new')?.then((_) {
                      controller.loadCategories();
                    }),
                    icon: const Icon(Icons.add),
                    label: const Text('Crear categoría'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: controller.loadCategories,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: controller.categories.length,
              itemBuilder: (context, index) {
                final category = controller.categories[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue,
                      child: Text(
                        category.name.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      category.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: category.description.isNotEmpty
                        ? Text(
                            category.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          )
                        : null,
                    trailing: Switch(
                      value: category.isActive,
                      onChanged: (value) =>
                          controller.toggleCategoryStatus(category.id, value),
                    ),
                  ),
                );
              },
            ),
          );
        }),
        floatingActionButton: Obx(() => controller.categories.isNotEmpty
            ? FloatingActionButton(
                onPressed: () => Get.toNamed('/categories/new')?.then((_) {
                  controller.loadCategories();
                }),
                child: const Icon(Icons.add),
              )
            : const SizedBox.shrink()),
      ),
    );
  }
}
