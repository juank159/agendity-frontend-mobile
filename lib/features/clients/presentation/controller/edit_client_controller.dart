import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:login_signup/features/clients/data/datasources/clients_remote_datasource.dart';
import 'package:login_signup/features/clients/data/models/client_model.dart';
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

  Rxn<ClientEntity> currentClient = Rxn<ClientEntity>();

  final isLoading = true.obs;
  final showNotes = false.obs;

  late TextEditingController nameController;
  late TextEditingController lastnameController;
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
    lastnameController = TextEditingController();
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
        imageQuality: 80,
      );

      if (image != null) {
        print('Imagen seleccionada:');
        print('Path: ${image.path}');

        // Convertir XFile a File
        final File imageFile = File(image.path);

        // Verificar que el archivo existe
        if (!imageFile.existsSync()) {
          throw Exception('No se pudo acceder al archivo seleccionado');
        }

        selectedImage.value = imageFile;
        await uploadImage();
      }
    } catch (e) {
      print('Error al seleccionar imagen: $e');
      Get.snackbar(
        'Error',
        'No se pudo seleccionar la imagen: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> uploadImage() async {
    if (selectedImage.value == null) return;

    try {
      isUploadingImage(true);

      print('Iniciando carga de imagen');
      print('Path del archivo: ${selectedImage.value!.path}');

      final String url =
          await remoteDataSource.uploadImage(selectedImage.value!);
      imageUrl.value = url;

      print('Imagen cargada exitosamente');
      print('URL recibida: $url');

      Get.snackbar(
        'Éxito',
        'Imagen cargada correctamente',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      print('Error en uploadImage: $e');
      Get.snackbar(
        'Error',
        'No se pudo cargar la imagen: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isUploadingImage(false);
    }
  }

  Future<void> updateClient() async {
    try {
      if (currentClient.value == null) {
        throw Exception('No se encontró información del cliente');
      }

      // Convertir fecha de string a DateTime si es necesario
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
        lastname: lastnameController.text,
        phone: phoneController.text,
        email: emailController.text,
        ownerId: currentClient.value!.ownerId,
        notes: notesController.text,
        birthday: birthday,
        showNotes: showNotes.value,
        image: imageUrl.value,
        isFromDevice: currentClient.value!.isFromDevice,
        deviceContactId: currentClient.value!.deviceContactId,
        isActive: currentClient.value!.isActive,
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
        'No se pudo actualizar el cliente: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> loadClient() async {
    try {
      isLoading(true);
      final client = await getClientByIdUseCase.execute(clientId);
      currentClient.value = client; // Añade esta línea

      nameController.text = client.name;
      lastnameController.text = client.lastname; // Añade esta línea
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
    lastnameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    notesController.dispose();
    birthdayController.dispose();
    super.onClose();
  }
}
