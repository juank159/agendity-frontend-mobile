import 'package:contacts_service/contacts_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/features/clients/domain/entities/client_entity.dart';
import 'package:login_signup/features/clients/domain/usecases/clients_usecases.dart';
import 'package:login_signup/shared/local_storage/local_storage.dart';
import 'package:permission_handler/permission_handler.dart';

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
      clients.value = await getClientsUseCase.execute();
    } catch (e) {
      _showError('Error al cargar clientes');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> importContacts() async {
    try {
      isLoading.value = true;
      if (await Permission.contacts.request().isGranted) {
        final deviceContacts = await ContactsService.getContacts();
        final ownerId = await localStorage.getToken();

        final newClients = deviceContacts.map((contact) {
          String phoneValue = '';
          if (contact.phones != null && contact.phones!.isNotEmpty) {
            phoneValue = contact.phones!.first.value ?? 'Sin teléfono';
          }

          return ClientEntity(
            name: contact.givenName ?? 'Sin nombre',
            lastname: contact.familyName ?? 'Sin apellido',
            email: contact.emails?.firstOrNull?.value ?? '',
            phone: phoneValue,
            ownerId: ownerId ?? '',
            isFromDevice: true,
            deviceContactId: contact.identifier ?? '',
          );
        }).toList();

        await importContactsUseCase.execute(newClients);
        await loadClients();
      }
    } catch (e) {
      _showError('Error al importar contactos');
    } finally {
      isLoading.value = false;
    }
  }

  void _showError(String message) {
    Get.snackbar('Error', message, backgroundColor: Colors.red);
  }
}
