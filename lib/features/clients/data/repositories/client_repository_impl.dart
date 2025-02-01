import 'package:login_signup/features/clients/data/datasources/clients_remote_datasource.dart';
import 'package:login_signup/features/clients/data/models/client_model.dart';
import 'package:login_signup/features/clients/domain/entities/client_entity.dart';
import 'package:login_signup/features/clients/domain/repositories/clients_repository.dart';

class ClientsRepositoryImpl implements ClientsRepository {
  final ClientsRemoteDataSource remoteDataSource;

  ClientsRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<ClientEntity>> getClients() async {
    try {
      final result = await remoteDataSource.getClients();
      return result.map((json) => ClientModel.fromJson(json)).toList();
    } catch (e, stackTrace) {
      print('Error en getClients: $e');
      print('StackTrace: $stackTrace');
      throw Exception('Error al cargar clientes: $e');
    }
  }

  @override
  Future<ClientEntity> getClientById(String id) async {
    try {
      final result = await remoteDataSource.getClientById(id);
      return ClientModel.fromJson(result);
    } catch (e, stackTrace) {
      print('Error en getClientById: $e');
      print('StackTrace: $stackTrace');
      throw Exception('Error al obtener cliente por ID: $e');
    }
  }

  @override
  Future<void> createClient(ClientEntity client) async {
    try {
      await remoteDataSource.createClient(client);
    } catch (e, stackTrace) {
      print('Error en createClient: $e');
      print('StackTrace: $stackTrace');
      throw Exception('Error al crear cliente: $e');
    }
  }

  @override
  Future<void> updateClient(String id, ClientEntity client) async {
    try {
      await remoteDataSource.updateClient(id, client);
    } catch (e, stackTrace) {
      print('Error en updateClient: $e');
      print('StackTrace: $stackTrace');
      throw Exception('Error al actualizar cliente: $e');
    }
  }

  @override
  Future<void> deleteClient(String id) async {
    try {
      await remoteDataSource.deleteClient(id);
    } catch (e, stackTrace) {
      print('Error en deleteClient: $e');
      print('StackTrace: $stackTrace');
      throw Exception('Error al eliminar cliente: $e');
    }
  }

  @override
  Future<void> importDeviceContacts(List<ClientEntity> clients) async {
    try {
      if (clients.isEmpty) {
        print('No hay contactos para importar');
        throw Exception('La lista de contactos está vacía');
      }

      // Filtrar clientes válidos
      final validClients = clients.where((client) {
        final isValid = _isValidClient(client);
        if (!isValid) {
          print('Cliente inválido descartado: ${client.name}');
        }
        return isValid;
      }).toList();

      if (validClients.isEmpty) {
        throw Exception('No hay contactos válidos para importar');
      }

      print(
          'Iniciando importación de ${validClients.length} contactos válidos');
      await remoteDataSource.importDeviceContacts(validClients);
      print('Importación de contactos completada exitosamente');
    } catch (e, stackTrace) {
      print('Error en importDeviceContacts: $e');
      print('StackTrace: $stackTrace');
      throw Exception('Error al importar contactos: $e');
    }
  }

// Mejorar la validación de clientes
  bool _isValidClient(ClientEntity client) {
    final isValidName = client.name.trim().isNotEmpty;
    final isValidPhone =
        client.phone.trim().isNotEmpty && client.phone.trim().length >= 10;
    final isValidOwnerId = client.ownerId.trim().isNotEmpty;

    if (!isValidName) print('Cliente inválido: nombre vacío');
    if (!isValidPhone)
      print('Cliente inválido: teléfono inválido - ${client.phone}');
    if (!isValidOwnerId) print('Cliente inválido: ownerId vacío');

    return isValidName && isValidPhone && isValidOwnerId;
  }
}
