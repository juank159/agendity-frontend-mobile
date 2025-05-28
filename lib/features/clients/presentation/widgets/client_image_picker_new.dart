// lib/features/clients/presentation/widgets/client_image_picker_new.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/new_client_controller.dart';

class ClientImagePickerNew extends GetView<NewClientController> {
  const ClientImagePickerNew({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Obx(() {
        Widget imageContent;

        if (controller.isUploadingImage.value) {
          // Si está cargando, mostrar indicador de progreso
          imageContent = const CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 3.0,
          );
        } else if (controller.selectedImage.value != null ||
            controller.imageUrl.value.isNotEmpty) {
          // Si hay una imagen seleccionada, no mostrar icono superpuesto
          imageContent = const SizedBox.shrink();
        } else {
          // Si no hay imagen, mostrar icono de cámara
          imageContent = const Icon(
            Icons.add_a_photo,
            color: Colors.white,
            size: 40,
          );
        }

        return Stack(
          children: [
            // Contenedor principal de la imagen
            Container(
              height: 160,
              width: 160,
              decoration: BoxDecoration(
                color: Colors.blue.shade300,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.shade300.withOpacity(0.5),
                    spreadRadius: 2,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                image: controller.imageUrl.value.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(controller.imageUrl.value),
                        fit: BoxFit.cover,
                      )
                    : controller.selectedImage.value != null
                        ? DecorationImage(
                            image: FileImage(controller.selectedImage.value!),
                            fit: BoxFit.cover,
                          )
                        : null,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => controller.pickImage(),
                  customBorder: const CircleBorder(),
                  child: Center(child: imageContent),
                ),
              ),
            ),

            // Botón de edición
            if (controller.selectedImage.value != null ||
                controller.imageUrl.value.isNotEmpty)
              Positioned(
                bottom: 5,
                right: 5,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade700,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.edit,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
          ],
        );
      }),
    );
  }
}
