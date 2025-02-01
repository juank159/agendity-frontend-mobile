// presentation/controllers/edit_client_controller.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:login_signup/features/clients/data/datasources/clients_remote_datasource.dart';
import 'package:login_signup/features/clients/domain/entities/client_entity.dart';
import 'package:login_signup/features/clients/domain/usecases/clients_usecases.dart';

class EditClientController extends GetxController {
  final GetClientByIdUseCase getClientByIdUseCase;
  final UpdateClientUseCase updateClientUseCase;
  final DeleteClientUseCase deleteClientUseCase;
  final ClientsRemoteDataSource remoteDataSource;

  final RxString imageUrl = ''.obs;
  final Rxn<File> selectedImage = Rxn<File>();
  final RxBool isUploadingImage = false.obs;

  final isLoading = true.obs;
  final showNotes = false.obs;

  late TextEditingController nameController;
  late TextEditingController phoneController;
  late TextEditingController emailController;
  late TextEditingController notesController;
  late TextEditingController birthdayController;

  late String clientId;

  EditClientController({
    required this.getClientByIdUseCase,
    required this.updateClientUseCase,
    required this.deleteClientUseCase,
    required this.remoteDataSource,
  });

  @override
  void onInit() {
    super.onInit();
    nameController = TextEditingController();
    phoneController = TextEditingController();
    emailController = TextEditingController();
    notesController = TextEditingController();
    birthdayController = TextEditingController();

    clientId = Get.arguments['clientId'];
    loadClient();
  }

  Future<void> pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80, // Comprimir imagen
      );

      if (image != null) {
        selectedImage.value = File(image.path);
        await uploadImage();
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'No se pudo seleccionar la imagen',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> uploadImage() async {
    if (selectedImage.value == null) return;

    try {
      isUploadingImage(true);

      final String url = clientId.isEmpty
          ? await remoteDataSource.uploadImage(selectedImage.value!)
          : await remoteDataSource.updateClientImage(
              clientId, selectedImage.value!);

      imageUrl.value = url;

      Get.snackbar(
        'Éxito',
        'Imagen cargada correctamente',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'No se pudo cargar la imagen',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isUploadingImage(false);
    }
  }

  Future<void> loadClient() async {
    try {
      isLoading(true);
      final client = await getClientByIdUseCase.execute(clientId);

      nameController.text = client.name;
      phoneController.text = client.phone;
      emailController.text = client.email;
      notesController.text = client.notes ?? '';
      birthdayController.text = client.birthday != null
          ? "${client.birthday!.day}/${client.birthday!.month}/${client.birthday!.year}"
          : '';
      showNotes.value = client.showNotes;

      if (client.image != null && client.image!.isNotEmpty) {
        imageUrl.value = client.image!;
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'No se pudo cargar el cliente',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading(false);
    }
  }

  Future<void> updateClient() async {
    try {
      final currentClient = await getClientByIdUseCase.execute(clientId);

      // Convertir string de fecha a DateTime
      DateTime? birthday;
      if (birthdayController.text.isNotEmpty) {
        final parts = birthdayController.text.split('/');
        if (parts.length == 3) {
          birthday = DateTime(
            int.parse(parts[2]), // año
            int.parse(parts[1]), // mes
            int.parse(parts[0]), // día
          );
        }
      }

      final updatedClient = ClientEntity(
        id: clientId,
        name: nameController.text,
        lastname: currentClient.lastname,
        phone: phoneController.text,
        email: emailController.text,
        ownerId: currentClient.ownerId,
        notes: notesController.text,
        birthday: birthday,
        showNotes: showNotes.value,
        image: imageUrl.value,
        isFromDevice: currentClient.isFromDevice,
        deviceContactId: currentClient.deviceContactId,
        isActive: currentClient.isActive,
      );

      await updateClientUseCase.execute(clientId, updatedClient);
      Get.back(result: true);
      Get.snackbar(
        'Éxito',
        'Cliente actualizado correctamente',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'No se pudo actualizar el cliente',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void showDeleteConfirmation() {
    Get.dialog(
      AlertDialog(
        title: const Text('Eliminar cliente'),
        content:
            const Text('¿Estás seguro de que deseas eliminar este cliente?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              await deleteClient();
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> deleteClient() async {
    try {
      await deleteClientUseCase.execute(clientId);
      Get.back(result: true);
      Get.snackbar('Éxito', 'Cliente eliminado correctamente');
    } catch (e) {
      Get.snackbar('Error', 'No se pudo eliminar el cliente');
    }
  }

  @override
  void onClose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    notesController.dispose();
    birthdayController.dispose();
    super.onClose();
  }
}
