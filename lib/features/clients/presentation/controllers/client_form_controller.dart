import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/features/clients/domain/entities/client_entity.dart';
import 'package:login_signup/features/clients/domain/usecases/upload_client_image_usecase.dart';
import 'package:login_signup/shared/widgets/app_snackbar.dart';
import 'client_access.dart';

/// Devuelve la ruta de una imagen elegida en el dispositivo, o `null` si el
/// usuario canceló.
typedef ImagePathPicker = Future<String?> Function();

Future<String?> _pickFromGallery() async => (await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 80))
    ?.path;

/// Estado común del formulario de cliente (alta y edición; Owner y Employee).
///
/// Las reglas del dato (nombre, teléfono, email) las valida el use case
/// (`InvalidClientDataFailure`); aquí solo se convierte lo que escribe el
/// usuario. La foto se sube al elegirla con `UploadClientImageUseCase` y se
/// guarda su URL.
abstract class ClientFormController extends GetxController {
  final UploadClientImageUseCase _uploadImage;
  final ImagePathPicker _pickImagePath;

  ClientFormController({
    required UploadClientImageUseCase uploadClientImageUseCase,
    ImagePathPicker? imagePicker,
  })  : _uploadImage = uploadClientImageUseCase,
        _pickImagePath = imagePicker ?? _pickFromGallery;

  final nameController = TextEditingController();
  final lastnameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final addressController = TextEditingController();
  final notesController = TextEditingController();

  final showNotes = false.obs;
  final birthday = Rxn<DateTime>();

  /// URL de la foto ya subida (vacía = sin foto).
  final imageUrl = ''.obs;
  final isUploadingImage = false.obs;
  final isSaving = false.obs;

  @override
  void onClose() {
    nameController.dispose();
    lastnameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    addressController.dispose();
    notesController.dispose();
    super.onClose();
  }

  /// Elige una foto y la sube. Si falla, se conserva la anterior.
  Future<void> pickImage() async {
    if (isUploadingImage.value) return;
    final String? path;
    try {
      path = await _pickImagePath();
    } catch (_) {
      AppSnackbar.error('No se pudo abrir la galería.');
      return;
    }
    if (path == null) return;

    isUploadingImage.value = true;
    final result = await _uploadImage(path);
    isUploadingImage.value = false;
    result.fold(
      (failure) => AppSnackbar.error(
          'No se pudo subir la foto: ${ClientAccess.messageFor(failure)}'),
      (url) => imageUrl.value = url,
    );
  }

  /// Rellena el formulario con [client].
  @protected
  void fill(ClientEntity client) {
    nameController.text = client.name;
    lastnameController.text = client.lastname;
    phoneController.text = client.phone;
    emailController.text = client.email ?? '';
    addressController.text = client.address ?? '';
    notesController.text = client.notes ?? '';
    showNotes.value = client.showNotes;
    birthday.value = client.birthday;
    imageUrl.value = client.image ?? '';
  }

  /// Lo escrito, sobre [base] (campos que el formulario no muestra). Vacío =
  /// sin valor (el use case lo normaliza).
  @protected
  ClientEntity formData({ClientEntity? base}) => ClientEntity(
        id: base?.id,
        name: nameController.text,
        lastname: lastnameController.text,
        phone: phoneController.text,
        email: emailController.text,
        address: addressController.text,
        notes: notesController.text,
        showNotes: showNotes.value,
        birthday: birthday.value,
        image: imageUrl.value,
        isFromDevice: base?.isFromDevice ?? false,
        deviceContactId: base?.deviceContactId,
        isActive: base?.isActive ?? true,
        lastVisit: base?.lastVisit,
        createdAt: base?.createdAt,
      );

  /// Guarda con [save] y vuelve a la lista con `result: true`.
  @protected
  Future<bool> runSave(
    Future<Failure?> Function() save, {
    required String successMessage,
  }) async {
    if (isSaving.value || isUploadingImage.value) return false;
    isSaving.value = true;
    final failure = await save();
    isSaving.value = false;
    if (failure != null) {
      await ClientAccess.show(failure);
      return false;
    }
    Get.back(result: true);
    AppSnackbar.success(successMessage);
    return true;
  }

  /// Guarda el formulario. `true` si se guardó.
  Future<bool> submit();
}
