import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/core/widgets/error_state.dart';
import 'package:login_signup/core/widgets/loading_state.dart';
import '../controller/edit_client_controller.dart';
import '../widgets/client_form.dart';

/// Edición de un cliente. Borrar solo lo ve el Owner.
class EditClientScreen extends GetView<EditClientController> {
  const EditClientScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar cliente')),
      body: Obx(() {
        switch (controller.status.value) {
          case EditClientStatus.loading:
            return const LoadingState(message: 'Cargando cliente…');
          case EditClientStatus.error:
            return ErrorState(
              title: 'No se pudo cargar',
              message: controller.loadError.value ?? '',
              onRetry: controller.load,
            );
          case EditClientStatus.ready:
            return const _EditClientBody();
        }
      }),
    );
  }
}

class _EditClientBody extends GetView<EditClientController> {
  const _EditClientBody();

  @override
  Widget build(BuildContext context) {
    final error = context.tokens.error.color;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClientForm(controller: controller),
            const SizedBox(height: 16),
            Obx(() {
              final busy = controller.isSaving.value ||
                  controller.isDeleting.value ||
                  controller.isUploadingImage.value;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton.icon(
                    onPressed: busy ? null : controller.submit,
                    icon: controller.isSaving.value
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.save),
                    label: const Text('Guardar cambios'),
                  ),
                  if (controller.canDelete) ...[
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: busy ? null : controller.delete,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: error,
                        side: BorderSide(color: error),
                      ),
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Eliminar cliente'),
                    ),
                  ],
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}
