//

import 'package:login_signup/features/clients/domain/entities/client_entity.dart';
import 'package:login_signup/features/clients/domain/repositories/clients_repository.dart';
import 'package:login_signup/features/clients/data/models/client_model.dart';

// ✅ NUEVO CASO DE USO PARA PAGINACIÓN
class GetClientsPaginatedUseCase {
  final ClientsRepository repository;
  GetClientsPaginatedUseCase(this.repository);
  
  Future<PaginatedClientResponse> execute({
    int page = 1,
    int limit = 10,
    String? search,
    String sortBy = 'created_at',
    String sortOrder = 'DESC',
    String status = 'all',
    String source = 'all',
  }) {
    print('🔥 GetClientsPaginatedUseCase: execute() llamado con parámetros:');
    print('   page: $page, limit: $limit, search: $search');
    return repository.getClientsPaginated(
      page: page,
      limit: limit,
      search: search,
      sortBy: sortBy,
      sortOrder: sortOrder,
      status: status,
      source: source,
    );
  }
}

// ✅ CASO DE USO LEGACY PARA RETROCOMPATIBILIDAD
class GetClientsUseCase {
  final ClientsRepository repository;
  GetClientsUseCase(this.repository);
  Future<List<ClientEntity>> execute() {
    print('🔥 GetClientsUseCase: execute() LEGACY llamado');
    return repository.getClients();
  }
}

class CreateClientUseCase {
  final ClientsRepository repository;
  CreateClientUseCase(this.repository);
  Future<void> execute(ClientEntity client) {
    return repository.createClient(client);
  }
}

class GetClientByIdUseCase {
  final ClientsRepository repository;
  GetClientByIdUseCase(this.repository);
  Future<ClientEntity> execute(String id) async {
    return await repository.getClientById(id);
  }
}

// Nuevo caso de uso para actualizar cliente
class UpdateClientUseCase {
  final ClientsRepository repository;
  UpdateClientUseCase(this.repository);

  Future<void> execute(String id, ClientEntity client) async {
    try {
      if (id.isEmpty) {
        throw Exception('ID de cliente no válido');
      }

      // Validar datos del cliente
      _validateClientData(client);

      await repository.updateClient(id, client);
    } catch (e) {
      throw Exception('Error al actualizar el cliente: $e');
    }
  }

  void _validateClientData(ClientEntity client) {
    if (client.name.trim().isEmpty) {
      throw Exception('El nombre es requerido');
    }
    if (client.phone.trim().isEmpty) {
      throw Exception('El teléfono es requerido');
    }
  }
}

// Nuevo caso de uso para eliminar cliente
class DeleteClientUseCase {
  final ClientsRepository repository;
  DeleteClientUseCase(this.repository);

  Future<void> execute(String id) async {
    try {
      if (id.isEmpty) {
        throw Exception('ID de cliente no válido');
      }
      await repository.deleteClient(id);
    } catch (e) {
      throw Exception('Error al eliminar el cliente: $e');
    }
  }
}

// ImportContactsUseCase existente...
class ImportContactsUseCase {
  final ClientsRepository repository;
  ImportContactsUseCase(this.repository);

  Future<Map<String, dynamic>> execute(List<ClientEntity> clients) async {
    try {
      if (clients.isEmpty) {
        throw Exception('No hay contactos para importar');
      }

      _validateClients(clients);

      int totalSent = 0;
      int totalSuccess = 0;
      int totalFailed = 0;
      List<dynamic> allErrors = [];

      const int batchSize = 50;
      for (var i = 0; i < clients.length; i += batchSize) {
        final int end =
            (i + batchSize < clients.length) ? i + batchSize : clients.length;
        final batch = clients.sublist(i, end);

        try {
          print('🔄 UseCase: Procesando lote ${(i ~/ batchSize) + 1} de ${(clients.length / batchSize).ceil()} (${batch.length} contactos)');
          
          final result = await repository.importDeviceContacts(batch);
          
          totalSent += batch.length;
          totalSuccess += result['success'] as int;
          totalFailed += result['failed'] as int;
          allErrors.addAll(result['errors'] as List);
          
          print('✅ Lote ${(i ~/ batchSize) + 1} completado: ${result['success']}/${batch.length} exitosos');
          
        } catch (e) {
          print('❌ Error importando lote ${(i ~/ batchSize) + 1}: $e');
          totalFailed += batch.length;
          allErrors.add('Lote ${(i ~/ batchSize) + 1}: $e');
          continue;
        }
      }

      final summary = {
        'totalSent': totalSent,
        'totalSuccess': totalSuccess,
        'totalFailed': totalFailed,
        'errors': allErrors,
      };

      print('🏁 UseCase - Resumen final de importación:');
      print('   • Total enviados: $totalSent');
      print('   • Total exitosos: $totalSuccess');
      print('   • Total fallidos: $totalFailed');

      return summary;
      
    } catch (e) {
      print('❌ Error en ImportContactsUseCase: $e');
      throw Exception('Error al importar contactos: $e');
    }
  }

  void _validateClients(List<ClientEntity> clients) {
    final invalidClients = clients.where((client) {
      final bool hasName = client.name.trim().isNotEmpty;
      final bool hasPhone = client.phone.trim().isNotEmpty;
      final bool hasOwnerId = client.ownerId.trim().isNotEmpty;

      return !hasName || !hasPhone || !hasOwnerId;
    }).toList();

    if (invalidClients.isNotEmpty) {
      print(
          'Se encontraron ${invalidClients.length} contactos con datos inválidos');
      throw Exception('Algunos contactos no tienen la información requerida');
    }
  }
}
