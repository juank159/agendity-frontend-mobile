import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/features/services/presentation/controllers/new_category_controller.dart';

/// Alta de una categoría de servicios (solo Owner).
class NewCategoryScreen extends GetView<NewCategoryController> {
  const NewCategoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final info = context.tokens.info;
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva categoría')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Card(
              color: info.container,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: info.onContainer),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Las categorías agrupan tus servicios (p. ej. Uñas, '
                        'Cejas, Cortes) y ordenan el catálogo.',
                        style: TextStyle(color: info.onContainer),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: controller.nameController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Nombre de la categoría',
                hintText: 'Ejemplo: Spa de uñas, Barbería…',
                prefixIcon: Icon(Icons.folder_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller.descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Descripción (opcional)',
                hintText: 'Qué servicios incluye esta categoría',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 32),
            Obx(() => FilledButton.icon(
                  onPressed: controller.isSaving.value ? null : controller.save,
                  icon: controller.isSaving.value
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.add),
                  label: const Text('Crear categoría'),
                  style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(50)),
                )),
          ],
        ),
      ),
    );
  }
}
