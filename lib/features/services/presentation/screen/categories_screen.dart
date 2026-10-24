import 'package:login_signup/core/routes/routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/widgets/list_state_view.dart';
import 'package:login_signup/features/services/domain/entities/category.dart';
import '../controller/categories_controller.dart';

class CategoriesScreen extends GetView<CategoriesController> {
  const CategoriesScreen({super.key});

  Future<void> _openNewCategory() async {
    final result = await Get.toNamed(GetRoutes.addCategory);
    if (result == true) controller.loadCategories();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
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
              Get.toNamed(GetRoutes.services);
            },
          ),
        ),
        body: Obx(() => ListStateView<CategoryEntity>(
              isLoading: controller.isLoading.value,
              items: controller.categories,
              emptyIcon: Icons.category_outlined,
              emptyMessage: 'No hay categorías',
              emptyActionLabel: 'Crear categoría',
              emptyActionIcon: Icons.add,
              onEmptyAction: _openNewCategory,
              builder: (context, categories) => RefreshIndicator(
                onRefresh: controller.loadCategories,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: CircleAvatar(
                          backgroundColor: scheme.primary,
                          child: Text(
                            category.name.substring(0, 1).toUpperCase(),
                            style: TextStyle(
                              color: scheme.onPrimary,
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
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit, color: scheme.primary),
                              onPressed: () =>
                                  controller.editCategory(category),
                            ),
                            Switch(
                              value: category.isActive,
                              onChanged: (value) =>
                                  controller.toggleCategoryStatus(category.id,
                                      value // Pasar el nuevo valor al método
                                      ),
                            ),
                          ],
                        ),
                        onTap: () => controller.editCategory(category),
                      ),
                    );
                  },
                ),
              ),
            )),
        floatingActionButton: Obx(() => controller.categories.isNotEmpty
            ? FloatingActionButton(
                // Modificado para manejar el resultado
                onPressed: _openNewCategory,
                child: const Icon(Icons.add),
              )
            : const SizedBox.shrink()),
      ),
    );
  }
}
