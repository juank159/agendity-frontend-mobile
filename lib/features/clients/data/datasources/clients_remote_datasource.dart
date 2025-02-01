import 'dart:io';

import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
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

  // Método privado para obtener el token y validarlo
  Future<String> _getValidToken() async {
    final token = await localStorage.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Token no disponible');
    }
    print('Token actual: $token');
    return token;
  }

  // Método privado para manejar errores de DioError
  String _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return 'Tiempo de conexión agotado';
      case DioExceptionType.sendTimeout:
        return 'Tiempo de envío agotado';
      case DioExceptionType.receiveTimeout:
        return 'Tiempo de respuesta agotado';
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final responseData = error.response?.data;
        return 'Error del servidor (${statusCode}): ${responseData?['message'] ?? 'Error desconocido'}';
      case DioExceptionType.cancel:
        return 'Solicitud cancelada';
      default:
        return 'Error de conexión: ${error.message}';
    }
  }

  Future<Map<String, dynamic>> getClientById(String id) async {
    try {
      final token = await localStorage.getToken();
      final response = await dio.get(
        '/clients/$id',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );
      return response.data;
    } catch (e) {
      print('Error en getClientById: $e');
      throw Exception('Error al obtener cliente por ID: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getClients() async {
    try {
      final token = await _getValidToken();
      print('Obteniendo lista de clientes...');

      final response = await dio.get(
        '/clients',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode == 200) {
        print('Clientes obtenidos exitosamente');
        return List<Map<String, dynamic>>.from(response.data);
      } else {
        throw Exception('Error al obtener clientes: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('DioError en getClients: ${e.message}');
      throw Exception(_handleDioError(e));
    } catch (e) {
      print('Error inesperado en getClients: $e');
      throw Exception('Error al cargar clientes: $e');
    }
  }

  Future<void> createClient(ClientEntity client) async {
    try {
      final token = await _getValidToken();
      print('Creando nuevo cliente...');

      final response = await dio.post(
        '/clients',
        data: (client as ClientModel).toJson(),
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode != 201 && response.statusCode != 200) {
        throw Exception('Error al crear cliente: ${response.statusCode}');
      }
      print('Cliente creado exitosamente');
    } on DioException catch (e) {
      print('DioError en createClient: ${e.message}');
      throw Exception(_handleDioError(e));
    } catch (e) {
      print('Error inesperado en createClient: $e');
      throw Exception('Error al crear cliente: $e');
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
      final token = await _getValidToken();
      final cleanClients = clients
          .map((client) => {
                'name': client.name.trim(),
                'lastname': client.lastname.trim(),
                'email': client.email.trim().isEmpty
                    ? 'no-email@example.com'
                    : client.email.trim(),
                'phone': client.phone.replaceAll(RegExp(r'[^\d+]'), ''),
              })
          .toList();

      final response = await dio.post(
        '/clients/batch',
        data: {'clients': cleanClients},
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode != 201 && response.statusCode != 200) {
        throw Exception('Error: ${response.data['message']}');
      }

      final result = response.data;
      print('Importados: ${result['success']} de ${result['total']} contactos');
      if (result['errors'].length > 0) {
        print('Errores: ${result['errors'].length}');
      }
    } catch (e) {
      print('Error en importación: $e');
      throw Exception('Error al importar contactos: $e');
    }
  }

  Future<String> uploadImage(File file) async {
    try {
      final token = await localStorage.getToken();

      // Crear form-data
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last,
          contentType: MediaType('image', 'jpeg'), // o detectar el tipo real
        ),
      });

      final response = await dio.post(
        '/clients/image',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      if (response.data['url'] == null) {
        throw Exception('No se recibió URL de imagen');
      }

      return response.data['url'];
    } catch (e) {
      print('Error subiendo imagen: $e');
      throw Exception('Error al subir imagen: $e');
    }
  }

  Future<String> updateClientImage(String clientId, File file) async {
    try {
      final token = await localStorage.getToken();

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last,
          contentType: MediaType('image', 'jpeg'),
        ),
      });

      final response = await dio.patch(
        '/clients/$clientId/image',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      if (response.data['url'] == null) {
        throw Exception('No se recibió URL de imagen');
      }

      return response.data['url'];
    } catch (e) {
      print('Error actualizando imagen: $e');
      throw Exception('Error al actualizar imagen: $e');
    }
  }
}
