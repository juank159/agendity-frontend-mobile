import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/widgets/app_gradient_button.dart';
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
                icon: Icon(Icons.delete_rounded, color: scheme.error),
                onPressed:
                    controller.isDeleting.value || controller.isSaving.value
                        ? null
                        : controller.delete,
              )),
        ],
      ),
      body: ServiceForm(controller: controller),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Obx(() => AppGradientButton(
                label: 'Guardar cambios',
                icon: Icons.check_rounded,
                expand: true,
                loading: controller.isSaving.value,
                onPressed:
                    controller.isDeleting.value ? null : controller.save,
              )),
        ),
      ),
    );
  }
}
