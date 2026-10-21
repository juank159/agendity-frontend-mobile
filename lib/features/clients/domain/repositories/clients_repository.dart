import 'package:login_signup/features/clients/domain/entities/client_entity.dart';
import 'package:login_signup/features/clients/data/models/client_model.dart';

abstract class ClientsRepository {
  // ✅ NUEVA FUNCIONALIDAD DE PAGINACIÓN
  Future<PaginatedClientResponse> getClientsPaginated({
    int page = 1,
    int limit = 10,
    String? search,
    String sortBy = 'created_at',
    String sortOrder = 'DESC',
    String status = 'all',
    String source = 'all',
  });
  
  // ✅ MÉTODO LEGACY PARA RETROCOMPATIBILIDAD
  Future<List<ClientEntity>> getClients();
  
  Future<ClientEntity> getClientById(String id);
  Future<void> createClient(ClientEntity client);
  Future<void> updateClient(String id, ClientEntity client);
  Future<void> deleteClient(String id);
  Future<Map<String, dynamic>> importDeviceContacts(List<ClientEntity> clients);
}
