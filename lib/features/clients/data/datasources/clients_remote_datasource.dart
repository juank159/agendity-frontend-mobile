import 'package:dio/dio.dart';
import 'package:login_signup/features/clients/data/models/client_model.dart';
import 'package:login_signup/features/clients/domain/entities/client_entity.dart';
import 'package:login_signup/shared/local_storage/local_storage.dart';

class ClientsRemoteDataSource {
  final Dio dio;
  final LocalStorage localStorage;

  ClientsRemoteDataSource({
    required this.dio,
    required this.localStorage,
  });

  Future<List<Map<String, dynamic>>> getClients() async {
    try {
      final token = await localStorage.getToken();
      final response = await dio.get(
        '/clients',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      throw Exception('Error loading clients: $e');
    }
  }

  Future<void> createClient(ClientEntity client) async {
    try {
      final token = await localStorage.getToken();
      await dio.post(
        '/clients',
        data: (client as ClientModel).toJson(),
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } catch (e) {
      throw Exception('Error creating client: $e');
    }
  }

  Future<void> updateClient(String id, ClientEntity client) async {
    try {
      final token = await localStorage.getToken();
      await dio.put(
        '/clients/$id',
        data: (client as ClientModel).toJson(),
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } catch (e) {
      throw Exception('Error updating client: $e');
    }
  }

  Future<void> deleteClient(String id) async {
    try {
      final token = await localStorage.getToken();
      await dio.delete(
        '/clients/$id',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } catch (e) {
      throw Exception('Error deleting client: $e');
    }
  }

  Future<void> importDeviceContacts(List<ClientEntity> clients) async {
    try {
      final token = await localStorage.getToken();
      await dio.post(
        '/clients/batch',
        data: {
          'clients': clients.map((c) => (c as ClientModel).toJson()).toList()
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } catch (e) {
      throw Exception('Error importing contacts: $e');
    }
  }
}
