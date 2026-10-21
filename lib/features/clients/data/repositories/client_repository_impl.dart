import 'package:login_signup/features/clients/data/datasources/clients_remote_datasource.dart';
import 'package:login_signup/features/clients/data/models/client_model.dart';
import 'package:login_signup/features/clients/domain/entities/client_entity.dart';
import 'package:login_signup/features/clients/domain/repositories/clients_repository.dart';

class ClientsRepositoryImpl implements ClientsRepository {
  final ClientsRemoteDataSource remoteDataSource;

  ClientsRepositoryImpl({required this.remoteDataSource});

  // ✅ NUEVA FUNCIONALIDAD DE PAGINACIÓN
  @override
  Future<PaginatedClientResponse> getClientsPaginated({
    int page = 1,
    int limit = 10,
    String? search,
    String sortBy = 'created_at',
    String sortOrder = 'DESC',
    String status = 'all',
    String source = 'all',
  }) async {
    try {
      print('🏛️ ClientsRepository: getClientsPaginated() llamado con parámetros:');
      print('   page: $page, limit: $limit, search: $search');
      print('   sortBy: $sortBy, sortOrder: $sortOrder');
      print('   status: $status, source: $source');
      
      final result = await remoteDataSource.getClients(
        page: page,
        limit: limit,
        search: search,
        sortBy: sortBy,
        sortOrder: sortOrder,
        status: status,
        source: source,
      );
      
      print('🏛️ ClientsRepository: Respuesta paginada recibida del DataSource');
      print('   Total: ${result['total']}, Página: ${result['page']}, Límite: ${result['limit']}');
      print('   Clientes en esta página: ${result['data']?.length ?? 0}');
      
      // Convertir la respuesta del backend a nuestro modelo de paginación
      final paginatedResponse = PaginatedResponse<ClientModel>.fromJson(
        result,
        (json) => ClientModel.fromJson(json),
      );
      
      print('🏛️ ClientsRepository: Respuesta paginada convertida exitosamente');
      return paginatedResponse;
      
    } catch (e, stackTrace) {
      print('❌ Error en ClientsRepository.getClientsPaginated: $e');
      print('StackTrace: $stackTrace');
      throw Exception('Error al cargar clientes paginados: $e');
    }
  }

  // ✅ MÉTODO LEGACY PARA RETROCOMPATIBILIDAD
  @override
  Future<List<ClientEntity>> getClients() async {
    try {
      print('🏛️ ClientsRepository: getClients() LEGACY llamado');
      final result = await remoteDataSource.getClientsLegacy();
      print('🏛️ ClientsRepository: Datos legacy recibidos del DataSource: ${result.length} clientes');
      final clients = result.map((json) => ClientModel.fromJson(json)).toList();
      print('🏛️ ClientsRepository: Clientes legacy convertidos a entidades: ${clients.length}');
      return clients;
    } catch (e, stackTrace) {
      print('❌ Error en ClientsRepository.getClients legacy: $e');
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
    } catch (e) {
      print('Error en updateClient: $e');
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
  Future<Map<String, dynamic>> importDeviceContacts(List<ClientEntity> clients) async {
    try {
      if (clients.isEmpty) {
        print('No hay contactos para importar');
        throw Exception('La lista de contactos está vacía');
      }

      // Filtrar clientes válidos en frontend
      final validClients = clients.where((client) {
        final isValid = _isValidClient(client);
        if (!isValid) {
          print('Cliente inválido descartado en frontend: ${client.name}');
        }
        return isValid;
      }).toList();

      if (validClients.isEmpty) {
        throw Exception('No hay contactos válidos para importar');
      }

      print('📤 Repository: Enviando ${validClients.length} contactos válidos al backend');
      final result = await remoteDataSource.importDeviceContacts(validClients);
      
      // ✅ LOGGING DETALLADO DE ESTADÍSTICAS
      print('📊 Repository - Estadísticas de importación:');
      print('   • Enviados al backend: ${validClients.length}');
      print('   • Procesados por backend: ${result['total']}');
      print('   • Importados exitosamente: ${result['success']}');
      print('   • Rechazados por backend: ${result['failed']}');
      
      if (result['errors'] != null && (result['errors'] as List).isNotEmpty) {
        print('❌ Errores en backend:');
        for (var error in result['errors']) {
          print('   • ${error}');
        }
      }
      
      return result;
      
    } catch (e, stackTrace) {
      print('❌ Error en Repository importDeviceContacts: $e');
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
