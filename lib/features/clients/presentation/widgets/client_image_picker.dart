import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/client_form_controller.dart';

/// Foto del cliente (alta y edición): toca para elegir otra; se sube al
/// elegirla.
class ClientImagePicker extends StatelessWidget {
  final ClientFormController controller;

  const ClientImagePicker({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Obx(() {
        final url = controller.imageUrl.value;
        final uploading = controller.isUploadingImage.value;
        return Semantics(
          button: true,
          label: url.isEmpty ? 'Agregar foto' : 'Cambiar foto',
          child: InkWell(
            onTap: uploading ? null : controller.pickImage,
            customBorder: const CircleBorder(),
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 56,
                  backgroundColor: scheme.primaryContainer,
                  foregroundColor: scheme.onPrimaryContainer,
                  backgroundImage: url.isEmpty ? null : NetworkImage(url),
                  child: uploading
                      ? const CircularProgressIndicator()
                      : url.isEmpty
                          ? const Icon(Icons.add_a_photo, size: 36)
                          : null,
                ),
                if (url.isNotEmpty && !uploading)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: scheme.primary,
                      foregroundColor: scheme.onPrimary,
                      child: const Icon(Icons.edit, size: 18),
                    ),
                  ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
