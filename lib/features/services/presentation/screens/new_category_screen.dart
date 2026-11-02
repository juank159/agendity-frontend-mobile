import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/core/widgets/app_gradient_button.dart';
import 'package:login_signup/features/services/presentation/controllers/new_category_controller.dart';
import 'package:login_signup/shared/widgets/app_note.dart';
import 'package:login_signup/shared/widgets/app_section_card.dart';

/// Alta de una categoría de servicios (solo Owner).
class NewCategoryScreen extends GetView<NewCategoryController> {
  const NewCategoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva categoría')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(top: 8, bottom: 24),
          children: [
            const AppNote(
              'Las categorías agrupan tus servicios (p. ej. Uñas, Cejas, '
              'Cortes) y ordenan el catálogo.',
              tone: AppTone.info,
              icon: Icons.lightbulb_rounded,
              margin: EdgeInsets.fromLTRB(16, 8, 16, 4),
            ),
            AppSectionCard(
              icon: Icons.folder_rounded,
              title: 'Datos de la categoría',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: controller.nameController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Nombre de la categoría',
                      hintText: 'Ejemplo: Spa de uñas, Barbería…',
                      prefixIcon: Icon(Icons.label_rounded),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller.descriptionController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Descripción (opcional)',
                      hintText: 'Qué servicios incluye esta categoría',
                      prefixIcon: Icon(Icons.notes_rounded),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Obx(() => AppGradientButton(
                    label: 'Crear categoría',
                    icon: Icons.add_rounded,
                    expand: true,
                    loading: controller.isSaving.value,
                    onPressed: controller.save,
                  )),
            ),
          ],
        ),
      ),
    );
  }
}
