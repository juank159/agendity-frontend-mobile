// lib/features/clients/presentation/controller/new_client_controller.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:login_signup/features/clients/domain/entities/client_entity.dart';
import 'package:login_signup/features/clients/domain/usecases/create_client_usecase.dart';
import 'package:login_signup/features/clients/domain/usecases/upload_client_image_usecase.dart';

class NewClientController extends GetxController {
  final CreateClientUseCase createClientUseCase;
  final UploadClientImageUseCase uploadClientImageUseCase;

  // Controladores para los campos de texto
  late TextEditingController nameController;
  late TextEditingController lastnameController;
  late TextEditingController phoneController;
  late TextEditingController emailController;
  late TextEditingController notesController;
  late TextEditingController birthdayController;
  late TextEditingController addressController;

  // Variables observables
  final RxBool showNotes = false.obs;
  final RxString imageUrl = ''.obs;
  final Rxn<File> selectedImage = Rxn<File>();
  final RxBool isUploadingImage = false.obs;
  final RxBool isLoading = false.obs;

  NewClientController({
    required this.createClientUseCase,
    required this.uploadClientImageUseCase,
  });

  @override
  void onInit() {
    super.onInit();
    // Inicializar controladores
    nameController = TextEditingController();
    lastnameController = TextEditingController();
    phoneController = TextEditingController();
    emailController = TextEditingController();
    notesController = TextEditingController();
    birthdayController = TextEditingController();
    addressController = TextEditingController();
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
          (await uploadClientImageUseCase(selectedImage.value!.path)).fold(
              (failure) => throw Exception(failure.message), (url) => url);
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

  Future<void> createClient() async {
    try {
      isLoading(true);

      // Convertir fecha de string a DateTime si existe
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

      // Crear el modelo del cliente con los campos necesarios
      final client = ClientEntity(
        name: nameController.text,
        lastname: lastnameController.text,
        phone: phoneController.text,
        email: emailController.text,
        notes: notesController.text.isEmpty ? null : notesController.text,
        birthday: birthday,
        showNotes: showNotes.value,
        image: imageUrl.value.isEmpty ? null : imageUrl.value,
        address: addressController.text.isEmpty ? null : addressController.text,
      );

      // Validar el cliente antes de enviarlo
      if (!_validateClientData(client)) {
        throw Exception('Por favor, complete los campos obligatorios');
      }

      // Enviar el cliente al servidor
      (await createClientUseCase(client))
          .fold((failure) => throw Exception(failure.message), (_) => null);

      // Mostrar mensaje de éxito y volver a la pantalla anterior
      Get.back(result: true);
      Get.snackbar(
        'Éxito',
        'Cliente creado correctamente',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      print('Error al crear cliente: $e');
      Get.snackbar(
        'Error',
        'No se pudo crear el cliente: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading(false);
    }
  }

  // Método de validación separado
  bool _validateClientData(ClientEntity client) {
    if (client.name.trim().isEmpty) {
      Get.snackbar('Error', 'El nombre es requerido',
          backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }
    if (client.phone.trim().isEmpty || client.phone.trim().length < 10) {
      Get.snackbar('Error', 'El teléfono debe tener al menos 10 dígitos',
          backgroundColor: Colors.red, colorText: Colors.white);
      return false;
    }
    return true;
  }

  @override
  void onClose() {
    // Liberar recursos
    nameController.dispose();
    lastnameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    notesController.dispose();
    birthdayController.dispose();
    addressController.dispose();
    super.onClose();
  }
}
