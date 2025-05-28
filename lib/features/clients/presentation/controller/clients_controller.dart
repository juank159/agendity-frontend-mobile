// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:flutter_contacts/flutter_contacts.dart';
// import 'package:login_signup/features/clients/data/models/client_model.dart';
// import 'package:login_signup/features/clients/domain/entities/client_entity.dart';
// import 'package:login_signup/features/clients/domain/usecases/clients_usecases.dart';
// import 'package:login_signup/shared/local_storage/local_storage.dart';

// class ClientsController extends GetxController {
//   final GetClientsUseCase getClientsUseCase;
//   final CreateClientUseCase createClientUseCase;
//   final ImportContactsUseCase importContactsUseCase;
//   final LocalStorage localStorage;

//   final RxList<ClientEntity> clients = <ClientEntity>[].obs;
//   final RxBool isLoading = false.obs;
//   final RxString searchQuery = ''.obs;

//   ClientsController({
//     required this.getClientsUseCase,
//     required this.createClientUseCase,
//     required this.importContactsUseCase,
//     required this.localStorage,
//   });

//   @override
//   void onInit() {
//     super.onInit();
//     loadClients();
//   }

//   Future<void> loadClients() async {
//     try {
//       isLoading.value = true;

//       final result = await getClientsUseCase.execute();
//       clients.assignAll(result);
//     } catch (e) {
//       _showError('Error al cargar los clientes');
//     } finally {
//       isLoading.value = false;
//     }
//   }

//   Future<void> importContacts() async {
//     if (!await FlutterContacts.requestPermission(readonly: true)) {
//       throw Exception('Se necesita permiso para acceder a los contactos');
//     }

//     try {
//       final contacts = await FlutterContacts.getContacts(
//         withProperties: true,
//         withPhoto: false,
//       );

//       final userId = await localStorage.getUserId();
//       if (userId == null) {
//         throw Exception('Error de autenticación');
//       }

//       final validContacts = contacts
//           .where((contact) =>
//               contact.name.first.trim().isNotEmpty &&
//               contact.phones.isNotEmpty &&
//               contact.phones.first.number
//                       .replaceAll(RegExp(r'[^\d+]'), '')
//                       .length >=
//                   10)
//           .map((contact) => ClientModel(
//                 name: contact.name.first.trim(),
//                 lastname: contact.name.last.trim(),
//                 email: contact.emails.isNotEmpty
//                     ? contact.emails.first.address
//                     : 'no-email@example.com',
//                 phone: contact.phones.first.number
//                     .replaceAll(RegExp(r'[^\d+]'), ''),
//                 ownerId: userId,
//               ))
//           .toList();

//       if (validContacts.isEmpty) {
//         throw Exception('No hay contactos válidos para importar');
//       }

//       await importContactsUseCase.execute(validContacts);
//       Get.back();
//       await loadClients();
//       _showSuccess('${validContacts.length} contactos importados');
//     } catch (e) {
//       throw Exception('Error al importar contactos: $e');
//     }
//   }

//   void _showSuccess(String message) {
//     Get.snackbar(
//       'Éxito',
//       message,
//       backgroundColor: Colors.green,
//       colorText: Colors.white,
//       snackPosition: SnackPosition.TOP,
//       duration: const Duration(seconds: 3),
//     );
//   }

//   void _showError(String message) {
//     Get.snackbar(
//       'Error',
//       message,
//       backgroundColor: Colors.red,
//       colorText: Colors.white,
//       snackPosition: SnackPosition.TOP,
//       duration: const Duration(seconds: 3),
//     );
//   }
// }

// lib/features/clients/presentation/controller/clients_controller.dart

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
  final RxList<ClientEntity> filteredClients = <ClientEntity>[].obs;
  final RxList<ClientEntity> paginatedClients = <ClientEntity>[].obs;
  final RxBool isLoading = false.obs;
  final RxString searchQuery = ''.obs;

  // Variables para filtrado
  final RxBool isFilterActive = false.obs;
  final Rxn<bool> activeFilter =
      Rxn<bool>(); // true = activos, false = inactivos, null = todos
  final Rxn<bool> sourceFilter =
      Rxn<bool>(); // true = importados, false = manuales, null = todos
  final Rxn<String> sortOrder = Rxn<
      String>(); // name_asc, name_desc, date_asc, date_desc, null = predeterminado

  // Variables para paginación
  final RxInt currentPage = 0.obs;
  final RxInt pageSize = 10.obs; // Clientes por página
  final RxInt totalPages = 0.obs;
  final RxBool hasMorePages = true.obs;
  final RxBool isLoadingMore = false.obs;
  final ScrollController scrollController = ScrollController();

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

    // Observar cambios en la búsqueda para aplicar filtros
    ever(searchQuery, (_) => applyFilters());

    // Configurar scroll controller para paginación
    scrollController.addListener(_scrollListener);
  }

  @override
  void onClose() {
    scrollController.removeListener(_scrollListener);
    scrollController.dispose();
    super.onClose();
  }

  // Escuchar el scroll para cargar más elementos cuando sea necesario
  void _scrollListener() {
    if (scrollController.position.pixels >=
            scrollController.position.maxScrollExtent - 200 &&
        !isLoadingMore.value &&
        hasMorePages.value) {
      loadMoreClients();
    }
  }

  Future<void> loadClients() async {
    try {
      isLoading.value = true;

      final result = await getClientsUseCase.execute();
      clients.assignAll(result);

      // Resetear paginación
      currentPage.value = 0;

      // Aplicar filtros iniciales
      applyFilters();
    } catch (e) {
      _showError('Error al cargar los clientes');
    } finally {
      isLoading.value = false;
    }
  }

  // Cargar más clientes (paginación)
  Future<void> loadMoreClients() async {
    if (!hasMorePages.value || isLoadingMore.value) return;

    try {
      isLoadingMore.value = true;

      // Simular una carga retrasada para mostrar el efecto
      await Future.delayed(const Duration(milliseconds: 500));

      // Incrementar la página actual
      currentPage.value++;

      // Aplicar paginación
      _applyPagination();
    } catch (e) {
      print('Error al cargar más clientes: $e');
    } finally {
      isLoadingMore.value = false;
    }
  }

  // Verifica si hay algún filtro activo
  void _checkFilterStatus() {
    isFilterActive.value = activeFilter.value != null ||
        sourceFilter.value != null ||
        sortOrder.value != null;
  }

  // Aplica todos los filtros y actualiza la lista filtrada
  void applyFilters() {
    if (clients.isEmpty) return;

    _checkFilterStatus();

    // Comenzar con todos los clientes
    List<ClientEntity> result = List.from(clients);

    // Aplicar filtro de búsqueda por texto
    if (searchQuery.value.isNotEmpty) {
      final query = searchQuery.value.toLowerCase();
      result = result.where((client) {
        final name = '${client.name} ${client.lastname}'.toLowerCase();
        final phone = client.phone.toLowerCase();
        final email = client.email.toLowerCase();
        return name.contains(query) ||
            phone.contains(query) ||
            email.contains(query);
      }).toList();
    }

    // Aplicar filtro por estado (activo/inactivo)
    if (activeFilter.value != null) {
      result = result
          .where((client) => client.isActive == activeFilter.value)
          .toList();
    }

    // Aplicar filtro por origen (importado/manual)
    if (sourceFilter.value != null) {
      result = result
          .where((client) => client.isFromDevice == sourceFilter.value)
          .toList();
    }

    // Aplicar ordenamiento
    if (sortOrder.value != null) {
      switch (sortOrder.value) {
        case 'name_asc':
          result.sort((a, b) =>
              '${a.name} ${a.lastname}'.compareTo('${b.name} ${b.lastname}'));
          break;
        case 'name_desc':
          result.sort((a, b) =>
              '${b.name} ${b.lastname}'.compareTo('${a.name} ${a.lastname}'));
          break;
        case 'date_asc':
          result.sort((a, b) {
            final dateA = a.createdAt ?? DateTime(1900);
            final dateB = b.createdAt ?? DateTime(1900);
            return dateA.compareTo(dateB);
          });
          break;
        case 'date_desc':
          result.sort((a, b) {
            final dateA = a.createdAt ?? DateTime(1900);
            final dateB = b.createdAt ?? DateTime(1900);
            return dateB.compareTo(dateA);
          });
          break;
      }
    }

    // Actualizar la lista filtrada
    filteredClients.assignAll(result);

    // Recalcular el número total de páginas
    totalPages.value = (filteredClients.length / pageSize.value).ceil();

    // Resetear a la primera página cuando se aplican filtros
    currentPage.value = 0;

    // Aplicar paginación
    _applyPagination();
  }

  // Aplica la paginación a la lista filtrada
  void _applyPagination() {
    if (filteredClients.isEmpty) {
      paginatedClients.clear();
      hasMorePages.value = false;
      return;
    }

    final start = 0;
    final end = (currentPage.value + 1) * pageSize.value;
    final actualEnd =
        end > filteredClients.length ? filteredClients.length : end;

    // Verificar si hay más páginas disponibles
    hasMorePages.value = actualEnd < filteredClients.length;

    // Obtener los clientes paginados (todos hasta la página actual)
    final paginatedResult = filteredClients.sublist(start, actualEnd);
    paginatedClients.assignAll(paginatedResult);
  }

  // Limpia todos los filtros
  void clearAllFilters() {
    activeFilter.value = null;
    sourceFilter.value = null;
    sortOrder.value = null;
    searchQuery.value = '';
    isFilterActive.value = false;

    // Resetear paginación
    currentPage.value = 0;

    // Re-aplicar filtros (que ahora son todos nulos)
    applyFilters();
  }

  // Refrescar la lista de clientes
  Future<void> refreshClients() async {
    await loadClients();
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
