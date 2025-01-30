// get_clients_usecase.dart
import 'package:login_signup/features/clients/domain/entities/client_entity.dart';
import 'package:login_signup/features/clients/domain/repositories/clients_repository.dart';

class GetClientsUseCase {
  final ClientsRepository repository;

  GetClientsUseCase(this.repository);

  Future<List<ClientEntity>> execute() {
    return repository.getClients();
  }
}

// create_client_usecase.dart
class CreateClientUseCase {
  final ClientsRepository repository;

  CreateClientUseCase(this.repository);

  Future<void> execute(ClientEntity client) {
    return repository.createClient(client);
  }
}

// import_contacts_usecase.dart
class ImportContactsUseCase {
  final ClientsRepository repository;

  ImportContactsUseCase(this.repository);

  Future<void> execute(List<ClientEntity> clients) {
    return repository.importDeviceContacts(clients);
  }
}
