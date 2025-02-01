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
          GestureDetector(
            onTap: () => controller.pickImage(),
            child: Obx(() {
              if (controller.isUploadingImage.value) {
                return Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (controller.imageUrl.isNotEmpty) {
                return Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      image: NetworkImage(controller.imageUrl.value),
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              }

              if (controller.selectedImage.value != null) {
                return Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      image: FileImage(controller.selectedImage.value!),
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              }

              return Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey),
                ),
                child: const Icon(Icons.camera_alt),
              );
            }),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(
                Icons.edit,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
