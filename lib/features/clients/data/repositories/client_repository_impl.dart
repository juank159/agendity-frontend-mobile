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
    } catch (e) {
      throw Exception('Error loading clients');
    }
  }

  @override
  Future<void> createClient(ClientEntity client) async {
    try {
      await remoteDataSource.createClient(client);
    } catch (e) {
      throw Exception('Error creating client');
    }
  }

  @override
  Future<void> updateClient(String id, ClientEntity client) async {
    try {
      await remoteDataSource.updateClient(id, client);
    } catch (e) {
      throw Exception('Error updating client');
    }
  }

  @override
  Future<void> deleteClient(String id) async {
    try {
      await remoteDataSource.deleteClient(id);
    } catch (e) {
      throw Exception('Error deleting client');
    }
  }

  @override
  Future<void> importDeviceContacts(List<ClientEntity> clients) async {
    try {
      await remoteDataSource.importDeviceContacts(clients);
    } catch (e) {
      throw Exception('Error importing contacts');
    }
  }
}
