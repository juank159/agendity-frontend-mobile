import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/features/services/presentation/controllers/edit_service_controller.dart';
import 'package:login_signup/features/services/presentation/widgets/service_form.dart';

/// Edición y borrado de un servicio (solo Owner).
class EditServiceScreen extends GetView<EditServiceController> {
  const EditServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar servicio'),
        actions: [
          Obx(() => IconButton(
                tooltip: 'Eliminar servicio',
                icon: Icon(Icons.delete_outline, color: scheme.error),
                onPressed: controller.isDeleting.value || controller.isSaving.value
                    ? null
                    : controller.delete,
              )),
        ],
      ),
      body: ServiceForm(controller: controller),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Obx(() => FilledButton.icon(
                onPressed: controller.isSaving.value || controller.isDeleting.value
                    ? null
                    : controller.save,
                icon: controller.isSaving.value
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.check),
                label: const Text('Guardar cambios'),
                style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(50)),
              )),
        ),
      ),
    );
  }
}
