//

import 'package:login_signup/features/clients/domain/entities/client_entity.dart';
import 'package:login_signup/features/clients/domain/repositories/clients_repository.dart';

// Casos de uso existentes...
class GetClientsUseCase {
  final ClientsRepository repository;
  GetClientsUseCase(this.repository);
  Future<List<ClientEntity>> execute() {
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
      print('Error en UpdateClientUseCase: $e');
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
      print('Error en DeleteClientUseCase: $e');
      throw Exception('Error al eliminar el cliente: $e');
    }
  }
}

// ImportContactsUseCase existente...
class ImportContactsUseCase {
  final ClientsRepository repository;
  ImportContactsUseCase(this.repository);

  Future<void> execute(List<ClientEntity> clients) async {
    try {
      if (clients.isEmpty) {
        throw Exception('No hay contactos para importar');
      }

      _validateClients(clients);

      const int batchSize = 50;
      for (var i = 0; i < clients.length; i += batchSize) {
        final int end =
            (i + batchSize < clients.length) ? i + batchSize : clients.length;
        final batch = clients.sublist(i, end);

        try {
          await repository.importDeviceContacts(batch);
          print(
              'Importado lote ${(i ~/ batchSize) + 1} de ${(clients.length / batchSize).ceil()}');
        } catch (e) {
          print('Error importando lote ${(i ~/ batchSize) + 1}: $e');
          continue;
        }
      }
    } catch (e) {
      print('Error en ImportContactsUseCase: $e');
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
