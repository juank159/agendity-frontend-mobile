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
  final GetClientsPaginatedUseCase getClientsPaginatedUseCase;
  final CreateClientUseCase createClientUseCase;
  final ImportContactsUseCase importContactsUseCase;
  final LocalStorage localStorage;

  // ✅ NUEVAS VARIABLES PARA PAGINACIÓN REAL DEL SERVIDOR
  final RxList<ClientEntity> clients = <ClientEntity>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxString searchQuery = ''.obs;

  // ✅ VARIABLES DE PAGINACIÓN DEL SERVIDOR
  final RxInt currentPage = 1.obs; // Empezar en página 1 (backend)
  final RxInt pageSize = 20.obs; // Clientes por página
  final RxInt totalRecords = 0.obs; // Total de registros en el servidor
  final RxInt totalPages = 0.obs; // Total de páginas en el servidor
  final RxBool hasNextPage = false.obs; // Si hay más páginas
  final RxBool hasPrevPage = false.obs; // Si hay página anterior

  // ✅ VARIABLES DE FILTRADO PARA EL SERVIDOR (ORDENAR A-Z POR DEFECTO)
  final RxString statusFilter = 'all'.obs; // all, active, inactive
  final RxString sourceFilter = 'all'.obs; // all, manual, imported
  final RxString sortBy = 'name'.obs; // name, lastname, email, phone, created_at (A-Z por defecto)
  final RxString sortOrder = 'ASC'.obs; // ASC, DESC (A-Z por defecto)
  
  final ScrollController scrollController = ScrollController();

  ClientsController({
    required this.getClientsUseCase,
    required this.getClientsPaginatedUseCase,
    required this.createClientUseCase,
    required this.importContactsUseCase,
    required this.localStorage,
  });

  @override
  void onInit() {
    super.onInit();
    loadClients();

    // ✅ OBSERVAR CAMBIOS EN LA BÚSQUEDA PARA RECARGAR DESDE EL SERVIDOR
    // Usar debounce para evitar demasiadas peticiones al servidor
    debounce(searchQuery, (_) => _reloadClientsFromServer(), time: const Duration(milliseconds: 500));
    
    // Configurar scroll controller para paginación
    scrollController.addListener(_scrollListener);
  }

  @override
  void onClose() {
    scrollController.removeListener(_scrollListener);
    scrollController.dispose();
    super.onClose();
  }

  // ✅ ESCUCHAR EL SCROLL PARA CARGAR MÁS PÁGINAS DEL SERVIDOR
  void _scrollListener() {
    if (scrollController.position.pixels >=
            scrollController.position.maxScrollExtent - 200 &&
        !isLoadingMore.value &&
        hasNextPage.value) {
      loadMoreClients();
    }
  }

  // ✅ RECARGAR CLIENTES DESDE EL SERVIDOR (USADO EN DEBOUNCE DE BÚSQUEDA)
  Future<void> _reloadClientsFromServer() async {
    currentPage.value = 1; // Resetear a la primera página
    await loadClients(); // Cargar la primera página con nuevos filtros
  }

  // ✅ CARGAR CLIENTES DESDE EL SERVIDOR CON PAGINACIÓN REAL
  Future<void> loadClients() async {
    try {
      isLoading.value = true;
      print('🔄 ClientsController: Cargando clientes con paginación del servidor...');

      final result = await getClientsPaginatedUseCase.execute(
        page: currentPage.value,
        limit: pageSize.value,
        search: searchQuery.value.isNotEmpty ? searchQuery.value : null,
        sortBy: sortBy.value,
        sortOrder: sortOrder.value,
        status: statusFilter.value,
        source: sourceFilter.value,
      );

      // ✅ ACTUALIZAR VARIABLES DE PAGINACIÓN CON DATOS DEL SERVIDOR
      totalRecords.value = result.total;
      totalPages.value = result.totalPages;
      hasNextPage.value = result.hasNextPage;
      hasPrevPage.value = result.hasPrevPage;

      // ✅ SI ES LA PRIMERA PÁGINA, REEMPLAZAR LOS CLIENTES
      // SI ES CARGA DE MÁS PÁGINAS, AÑADIR AL FINAL
      if (currentPage.value == 1) {
        clients.assignAll(result.data);
        print('✅ Primera página cargada: ${result.data.length} clientes');
      } else {
        clients.addAll(result.data);
        print('✅ Página ${currentPage.value} agregada: ${result.data.length} clientes más');
      }

      print('📊 Total clientes en memoria: ${clients.length}');
      print('📊 Total en servidor: ${totalRecords.value}');
      print('📊 Página ${currentPage.value}/${totalPages.value}');
      print('📊 Tiene siguiente: ${hasNextPage.value}');

    } catch (e) {
      print('❌ Error al cargar clientes: $e');
      _showError('Error al cargar los clientes: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ✅ CARGAR MÁS CLIENTES DESDE EL SERVIDOR (SIGUIENTE PÁGINA)
  Future<void> loadMoreClients() async {
    if (!hasNextPage.value || isLoadingMore.value) return;

    try {
      isLoadingMore.value = true;
      print('🔄 Cargando página ${currentPage.value + 1}...');

      // ✅ GUARDAR POSICIÓN ACTUAL DEL SCROLL ANTES DE CARGAR MÁS
      final double currentPosition = scrollController.offset;
      final int currentItemsCount = clients.length;

      // Incrementar la página para cargar la siguiente
      currentPage.value++;

      // Cargar la siguiente página (se agregará a los clientes existentes)
      await loadClients();

      // ✅ MANTENER POSICIÓN RELATIVA DEL SCROLL
      // Calcular nueva posición basada en los nuevos elementos cargados
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (scrollController.hasClients) {
          // Mantener aproximadamente la misma posición relativa
          const double itemHeight = 90; // Altura aproximada de cada card
          final double newPosition = currentPosition + (itemHeight * 0.5); // Ajuste suave
          
          scrollController.animateTo(
            newPosition.clamp(0.0, scrollController.position.maxScrollExtent),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });

    } catch (e) {
      print('❌ Error al cargar más clientes: $e');
      // Revertir el incremento de página en caso de error
      currentPage.value--;
      _showError('Error al cargar más clientes');
    } finally {
      isLoadingMore.value = false;
    }
  }

  // ✅ MÉTODOS PARA APLICAR FILTROS EN EL SERVIDOR
  Future<void> applyStatusFilter(String status) async {
    if (statusFilter.value != status) {
      statusFilter.value = status;
      await _reloadClientsFromServer();
    }
  }

  Future<void> applySourceFilter(String source) async {
    if (sourceFilter.value != source) {
      sourceFilter.value = source;
      await _reloadClientsFromServer();
    }
  }

  Future<void> applySortFilter(String sortByField, String order) async {
    if (sortBy.value != sortByField || sortOrder.value != order) {
      sortBy.value = sortByField;
      sortOrder.value = order;
      await _reloadClientsFromServer();
    }
  }

  // ✅ VERIFICAR SI HAY FILTROS ACTIVOS (CONSIDERANDO A-Z COMO DEFECTO)
  bool get hasActiveFilters {
    return searchQuery.value.isNotEmpty ||
        statusFilter.value != 'all' ||
        sourceFilter.value != 'all' ||
        sortBy.value != 'name' ||
        sortOrder.value != 'ASC';
  }

  // ✅ LIMPIAR TODOS LOS FILTROS Y RECARGAR DESDE EL SERVIDOR (A-Z POR DEFECTO)
  Future<void> clearAllFilters() async {
    searchQuery.value = '';
    statusFilter.value = 'all';
    sourceFilter.value = 'all';
    sortBy.value = 'name'; // A-Z por defecto
    sortOrder.value = 'ASC'; // A-Z por defecto
    
    await _reloadClientsFromServer();
  }

  // ✅ REFRESCAR LA LISTA DE CLIENTES (PULL TO REFRESH)
  Future<void> refreshClients() async {
    await _reloadClientsFromServer();
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

      print('🔄 Iniciando importación de ${validContacts.length} contactos...');
      
      Map<String, dynamic> importResult;
      try {
        importResult = await importContactsUseCase.execute(validContacts);
        print('✅ Importación completada en UseCase');
      } catch (e) {
        print('❌ Error en importContactsUseCase: $e');
        throw e;
      }
      
      try {
        print('🔄 Recargando lista de clientes...');
        await loadClients();
        print('✅ Lista de clientes recargada exitosamente');
      } catch (e) {
        print('❌ Error al recargar clientes: $e');
        throw e;
      }
      
      try {
        print('🎉 Mostrando mensaje de éxito...');
        
        // ✅ MENSAJE DETALLADO CON ESTADÍSTICAS REALES
        final int sent = validContacts.length;
        final int success = importResult['totalSuccess'] as int;
        final int failed = importResult['totalFailed'] as int;
        
        String message;
        if (failed > 0) {
          message = '$success de $sent contactos importados exitosamente\n($failed rechazados por duplicados o datos inválidos)';
        } else {
          message = '$success contactos importados exitosamente';
        }
        
        _showSuccess(message);
        print('✅ Mensaje de éxito mostrado: $success exitosos, $failed fallidos');
      } catch (e) {
        print('❌ Error al mostrar mensaje: $e');
        throw e;
      }
      
      print('🏁 Función importContacts completada exitosamente');
      
    } catch (e) {
      print('❌ Error durante importación: $e');
      throw Exception('Error al importar contactos: $e');
    }
  }

  void _showSuccess(String message) {
    Get.snackbar(
      '🎉 Importación Exitosa',
      message,
      backgroundColor: Colors.green.shade600,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 4),
      icon: const Icon(
        Icons.check_circle_outline,
        color: Colors.white,
        size: 32,
      ),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
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
