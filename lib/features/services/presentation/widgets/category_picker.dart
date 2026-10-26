import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/features/services/domain/entities/category.dart';

/// Lista de categorías para elegir la de un servicio. Devuelve la elegida o
/// `null` si se cancela. Las inactivas se muestran marcadas.
class CategoryPicker extends StatelessWidget {
  final List<CategoryEntity> categories;
  final String? selectedId;

  const CategoryPicker({
    super.key,
    required this.categories,
    this.selectedId,
  });

  static Future<CategoryEntity?> show(
    List<CategoryEntity> categories, {
    String? selectedId,
  }) =>
      Get.dialog<CategoryEntity>(
        CategoryPicker(categories: categories, selectedId: selectedId),
      );

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: const Text('Categoría del servicio'),
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      content: SizedBox(
        width: 320,
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final category in categories)
              ListTile(
                title: Text(category.name),
                subtitle: category.isActive ? null : const Text('Inactiva'),
                trailing: category.id == selectedId
                    ? Icon(Icons.check_circle, color: scheme.primary)
                    : null,
                selected: category.id == selectedId,
                onTap: () => Navigator.of(context).pop(category),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }
}
