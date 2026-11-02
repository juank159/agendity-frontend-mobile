import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/core/widgets/app_fade_in.dart';
import 'package:login_signup/core/widgets/app_gradient_button.dart';
import 'package:login_signup/core/widgets/list_state_view.dart';
import 'package:login_signup/features/services/domain/entities/category.dart';
import 'package:login_signup/shared/widgets/app_card.dart';
import 'package:login_signup/shared/widgets/app_pill.dart';
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
          emptyIcon: Icons.folder_copy_rounded,
          emptyMessage: 'No hay categorías',
          emptySubMessage: canManage
              ? 'Agrupa tus servicios en categorías (p. ej. Uñas, Cejas).'
              : null,
          emptyActionLabel: canManage ? 'Crear categoría' : null,
          emptyActionIcon: Icons.add_rounded,
          onEmptyAction: canManage ? controller.openNewCategory : null,
          builder: (context, categories) => RefreshIndicator(
            onRefresh: controller.loadCategories,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 104),
              itemCount: categories.length,
              itemBuilder: (context, index) => AppFadeIn(
                index: index,
                child: _CategoryTile(
                  category: categories[index],
                  canManage: canManage,
                ),
              ),
            ),
          ),
        );
      }),
      floatingActionButton: Obx(() =>
          controller.canManage && controller.categories.isNotEmpty
              ? AppGradientButton.fab(
                  label: 'Categoría',
                  tooltip: 'Agregar categoría',
                  onPressed: controller.openNewCategory,
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = context.tokens;
    final count = category.serviceCount;
    final active = category.isActive;
    return AppCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
      depth: 1,
      onTap: canManage ? () => controller.editCategory(category) : null,
      semanticLabel: canManage ? 'Editar ${category.name}' : null,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: active ? tokens.primaryGradient : null,
              color: active ? null : scheme.surfaceContainerHighest,
              borderRadius: AppRadii.fieldRadius,
              border: Border.all(color: tokens.innerBorder),
            ),
            child: Icon(Icons.folder_rounded,
                color: active ? tokens.onGradient : scheme.onSurfaceVariant),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(category.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700, color: scheme.onSurface)),
                if (category.description.isNotEmpty)
                  Text(category.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant)),
                if (count != null || !active) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (count != null)
                        AppPill(
                          dense: true,
                          tabular: true,
                          icon: Icons.spa_rounded,
                          label:
                              count == 1 ? '1 servicio' : '$count servicios',
                        ),
                      if (!active)
                        AppPill(
                          dense: true,
                          icon: Icons.visibility_off_rounded,
                          label: 'Inactiva',
                          colors: tokens.warning,
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (canManage) _actions(scheme),
        ],
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
          icon: const Icon(Icons.more_vert_rounded),
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
                leading: Icon(Icons.edit_rounded),
                title: Text('Editar'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: _CategoryAction.delete,
              child: ListTile(
                leading: Icon(Icons.delete_rounded, color: scheme.error),
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
