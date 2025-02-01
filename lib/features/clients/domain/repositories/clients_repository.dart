import 'package:login_signup/features/clients/domain/entities/client_entity.dart';

abstract class ClientsRepository {
  Future<List<ClientEntity>> getClients();
  Future<ClientEntity> getClientById(String id);
  Future<void> createClient(ClientEntity client);
  Future<void> updateClient(String id, ClientEntity client);
  Future<void> deleteClient(String id);
  Future<void> importDeviceContacts(List<ClientEntity> clients);
}
