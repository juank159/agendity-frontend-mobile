import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/shared/widgets/app_avatar.dart';
import '../controllers/client_form_controller.dart';

/// Foto del cliente (alta y edición): el avatar de la guía (foto o iniciales
/// sobre el degradado) con una insignia de cámara; toca para elegir otra. Se
/// sube al elegirla.
class ClientImagePicker extends StatelessWidget {
  final ClientFormController controller;
  final double radius;

  const ClientImagePicker(
      {super.key, required this.controller, this.radius = 48});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = context.tokens;
    return Center(
      child: Obx(() {
        final url = controller.imageUrl.value;
        final uploading = controller.isUploadingImage.value;
        return Semantics(
          container: true,
          button: true,
          label: url.isEmpty ? 'Agregar foto' : 'Cambiar foto',
          excludeSemantics: true,
          child: InkWell(
            onTap: uploading ? null : controller.pickImage,
            customBorder: const CircleBorder(),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: controller.nameController,
                  builder: (context, name, _) => ValueListenableBuilder<
                      TextEditingValue>(
                    valueListenable: controller.lastnameController,
                    builder: (context, lastname, _) => AppAvatar(
                      name: '${name.text} ${lastname.text}'.trim(),
                      imageUrl: url.isEmpty ? null : url,
                      radius: radius,
                    ),
                  ),
                ),
                if (uploading)
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: scheme.scrim.withValues(alpha: 0.35),
                      ),
                      child: Center(
                        child: CircularProgressIndicator(
                            color: tokens.onGradient),
                      ),
                    ),
                  ),
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: scheme.surface,
                      boxShadow: tokens.elevation1(),
                    ),
                    padding: const EdgeInsets.all(3),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: scheme.primaryContainer,
                      ),
                      child: Icon(
                        url.isEmpty
                            ? Icons.add_a_photo_rounded
                            : Icons.photo_camera_rounded,
                        size: 16,
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
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
