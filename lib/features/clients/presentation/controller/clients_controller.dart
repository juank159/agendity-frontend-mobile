import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:login_signup/features/clients/data/models/client_model.dart';
import 'package:login_signup/features/clients/domain/entities/client_entity.dart';
import 'package:login_signup/features/clients/domain/usecases/clients_usecases.dart';
import 'package:login_signup/shared/local_storage/local_storage.dart';

class ClientsController extends GetxController {
  final GetClientsUseCase getClientsUseCase;
  final CreateClientUseCase createClientUseCase;
  final ImportContactsUseCase importContactsUseCase;
  final LocalStorage localStorage;

  final RxList<ClientEntity> clients = <ClientEntity>[].obs;
  final RxBool isLoading = false.obs;
  final RxString searchQuery = ''.obs;

  ClientsController({
    required this.getClientsUseCase,
    required this.createClientUseCase,
    required this.importContactsUseCase,
    required this.localStorage,
  });

  @override
  void onInit() {
    super.onInit();
    loadClients();
  }

  Future<void> loadClients() async {
    try {
      isLoading.value = true;

      final result = await getClientsUseCase.execute();
      clients.assignAll(result);
    } catch (e) {
      _showError('Error al cargar los clientes');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> importContacts() async {
    if (!await FlutterContacts.requestPermission(readonly: true)) {
      throw Exception('Se necesita permiso para acceder a los contactos');
    }

    try {
      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: false,
      );

      final userId = await localStorage.getUserId();
      if (userId == null) {
        throw Exception('Error de autenticación');
      }

      final validContacts = contacts
          .where((contact) =>
              contact.name.first.trim().isNotEmpty &&
              contact.phones.isNotEmpty &&
              contact.phones.first.number
                      .replaceAll(RegExp(r'[^\d+]'), '')
                      .length >=
                  10)
          .map((contact) => ClientModel(
                name: contact.name.first.trim(),
                lastname: contact.name.last.trim(),
                email: contact.emails.isNotEmpty
                    ? contact.emails.first.address
                    : 'no-email@example.com',
                phone: contact.phones.first.number
                    .replaceAll(RegExp(r'[^\d+]'), ''),
                ownerId: userId,
              ))
          .toList();

      if (validContacts.isEmpty) {
        throw Exception('No hay contactos válidos para importar');
      }

      await importContactsUseCase.execute(validContacts);
      Get.back();
      await loadClients();
      _showSuccess('${validContacts.length} contactos importados');
    } catch (e) {
      throw Exception('Error al importar contactos: $e');
    }
  }

  void _showSuccess(String message) {
    Get.snackbar(
      'Éxito',
      message,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 3),
    );
  }

  void _showError(String message) {
    Get.snackbar(
      'Error',
      message,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 3),
    );
  }
}
