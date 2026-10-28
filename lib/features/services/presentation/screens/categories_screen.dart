import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/core/widgets/list_state_view.dart';
import 'package:login_signup/features/services/domain/entities/category.dart';
import '../controllers/categories_controller.dart';

enum _CategoryAction { edit, delete }

/// Categorías del catálogo. El Owner crea, edita, activa/desactiva y borra;
/// el Employee solo las ve.
class CategoriesScreen extends GetView<CategoriesController> {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Categorías de servicio')),
      body: Obx(() {
        final canManage = controller.canManage;
        return ListStateView<CategoryEntity>(
          isLoading: controller.isLoading.value,
          error: controller.loadError.value,
          items: controller.categories.toList(),
          onRetry: controller.loadCategories,
          loadingMessage: 'Cargando categorías…',
          emptyIcon: Icons.folder_outlined,
          emptyMessage: 'No hay categorías',
          emptySubMessage: canManage
              ? 'Agrupa tus servicios en categorías (p. ej. Uñas, Cejas).'
              : null,
          emptyActionLabel: canManage ? 'Crear categoría' : null,
          emptyActionIcon: Icons.add,
          onEmptyAction: canManage ? controller.openNewCategory : null,
          builder: (context, categories) => RefreshIndicator(
            onRefresh: controller.loadCategories,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
              itemCount: categories.length,
              itemBuilder: (context, index) => _CategoryTile(
                category: categories[index],
                canManage: canManage,
              ),
            ),
          ),
        );
      }),
      floatingActionButton: Obx(() =>
          controller.canManage && controller.categories.isNotEmpty
              ? FloatingActionButton.extended(
                  onPressed: controller.openNewCategory,
                  icon: const Icon(Icons.add),
                  label: const Text('Categoría'),
                )
              : const SizedBox.shrink()),
    );
  }
}

class _CategoryTile extends GetView<CategoriesController> {
  final CategoryEntity category;
  final bool canManage;

  const _CategoryTile({required this.category, required this.canManage});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = context.tokens;
    final count = category.serviceCount;
    final details = [
      if (category.description.isNotEmpty) category.description,
      if (count != null) count == 1 ? '1 servicio' : '$count servicios',
      if (!category.isActive) 'Inactiva',
    ];
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              category.isActive ? scheme.primary : tokens.warning.container,
          foregroundColor:
              category.isActive ? scheme.onPrimary : tokens.warning.onContainer,
          child: Text(category.name.isEmpty
              ? '?'
              : category.name.substring(0, 1).toUpperCase()),
        ),
        title: Text(category.name,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: details.isEmpty
            ? null
            : Text(details.join(' · '),
                maxLines: 2, overflow: TextOverflow.ellipsis),
        onTap: canManage ? () => controller.editCategory(category) : null,
        trailing: canManage ? _actions(scheme) : null,
      ),
    );
  }

  Widget _actions(ColorScheme scheme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Obx(() => Switch(
              value: category.isActive,
              onChanged: controller.isBusy.value
                  ? null
                  : (value) => controller.setActive(category, value),
            )),
        PopupMenuButton<_CategoryAction>(
          tooltip: 'Más acciones',
          onSelected: (action) {
            switch (action) {
              case _CategoryAction.edit:
                controller.editCategory(category);
              case _CategoryAction.delete:
                controller.deleteCategory(category);
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(
              value: _CategoryAction.edit,
              child: ListTile(
                leading: Icon(Icons.edit_outlined),
                title: Text('Editar'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: _CategoryAction.delete,
              child: ListTile(
                leading: Icon(Icons.delete_outline, color: scheme.error),
                title: Text('Eliminar', style: TextStyle(color: scheme.error)),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
