// lib/features/clients/presentation/widgets/client_image_picker.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/edit_client_controller.dart';

class ClientImagePicker extends GetView<EditClientController> {
  const ClientImagePicker({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        children: [
          Obx(() {
            final imageWidget = controller.selectedImage.value != null
                ? CircleAvatar(
                    radius: 60,
                    backgroundImage: FileImage(controller.selectedImage.value!),
                  )
                : controller.imageUrl.value.isNotEmpty
                    ? CircleAvatar(
                        radius: 60,
                        backgroundImage:
                            NetworkImage(controller.imageUrl.value),
                      )
                    : const CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey,
                        child:
                            Icon(Icons.person, size: 60, color: Colors.white),
                      );

            return GestureDetector(
              onTap: () => controller.pickImage(),
              child: imageWidget,
            );
          }),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.camera_alt,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
