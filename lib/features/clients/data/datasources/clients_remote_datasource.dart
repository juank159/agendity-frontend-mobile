import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:login_signup/features/clients/data/models/client_model.dart';
import 'package:login_signup/features/clients/domain/entities/client_entity.dart';
import 'package:login_signup/shared/local_storage/local_storage.dart';
import 'package:image/image.dart' as img;

class ClientsRemoteDataSource {
  final Dio dio;
  final LocalStorage localStorage;

  ClientsRemoteDataSource({
    required this.dio,
    required this.localStorage,
  }) {
    // Configurar timeouts más largos para subida de archivos
    dio.options.connectTimeout = const Duration(seconds: 60);
    dio.options.receiveTimeout = const Duration(seconds: 60);
    dio.options.sendTimeout = const Duration(seconds: 60);
  }

  Future<String> _getValidToken() async {
    final token = await localStorage.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Token no disponible');
    }
    print('Token actual: $token');
    return token;
  }

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
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.data;
    } catch (e) {
      throw Exception('Error al obtener cliente por ID: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getClients() async {
    try {
      final token = await _getValidToken();
      final response = await dio.get(
        '/clients',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data);
      } else {
        throw Exception('Error al obtener clientes: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Error al cargar clientes: $e');
    }
  }

  Future<void> createClient(ClientEntity client) async {
    try {
      final token = await _getValidToken();
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
    } on DioException catch (e) {
      throw Exception(_handleDioError(e));
    } catch (e) {
      throw Exception('Error al crear cliente: $e');
    }
  }

  // Future<void> updateClient(String id, ClientEntity client) async {
  //   try {
  //     final token = await localStorage.getToken();

  //     print('Iniciando actualización de cliente ID: $id');

  //     // Solo incluimos los campos que el backend espera para actualización
  //     final clientData = {
  //       'name': client.name.trim(),
  //       'lastname': client.lastname.trim(),
  //       'email': client.email.trim(),
  //       'phone': client.phone.replaceAll(RegExp(r'[^\d+]'), ''),
  //       'notes': client.notes?.trim(),
  //       'birthday': client.birthday?.toIso8601String(),
  //       'showNotes': client.showNotes,
  //       'address': client.address?.trim(),
  //     };

  //     print('Datos a enviar al servidor:');
  //     print(clientData);

  //     final response = await dio.patch(
  //       '/clients/$id',
  //       data: clientData,
  //       options: Options(
  //         headers: {'Authorization': 'Bearer $token'},
  //         validateStatus: (status) => status! < 500,
  //       ),
  //     );

  //     print('Respuesta del servidor:');
  //     print('Status Code: ${response.statusCode}');
  //     print('Response Data: ${response.data}');

  //     if (response.statusCode != 200) {
  //       throw Exception(
  //           'Error al actualizar cliente: ${response.data['message'] ?? 'Error desconocido'}');
  //     }
  //   } on DioException catch (e) {
  //     print('Error de Dio durante la actualización:');
  //     print('Tipo de error: ${e.type}');
  //     print('Mensaje: ${e.message}');
  //     print('Response data: ${e.response?.data}');
  //     throw Exception(_handleDioError(e));
  //   } catch (e) {
  //     print('Error general durante la actualización: $e');
  //     throw Exception('Error al actualizar cliente: $e');
  //   }
  // }

  Future<void> updateClient(String id, ClientEntity client) async {
    try {
      final token = await localStorage.getToken();

      final clientData = {
        'name': client.name,
        'lastname': client.lastname,
        'email': client.email,
        'phone': client.phone,
        'notes': client.notes,
        'birthday': client.birthday?.toIso8601String(),
        'showNotes': client.showNotes,
        'image': client.image, // Asegúrate de incluir la imagen
        'address': client.address,
      };

      print('Datos a enviar al servidor:');
      print(clientData);

      final response = await dio.patch(
        '/clients/$id',
        data: clientData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      print('Respuesta del servidor:');
      print('Status Code: ${response.statusCode}');
      print('Response Data: ${response.data}');
    } catch (e) {
      print('Error al actualizar cliente: $e');
      throw Exception('Error al actualizar cliente: $e');
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
      throw Exception('Error al eliminar cliente: $e');
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
    } catch (e) {
      throw Exception('Error al importar contactos: $e');
    }
  }

  Future<String> uploadImage(File file) async {
    try {
      final token = await localStorage.getToken();

      if (!file.existsSync()) {
        throw Exception('El archivo no existe');
      }

      // Comprimir la imagen antes de enviarla
      final compressedFile = await compressImage(file);
      final fileName = compressedFile.path.split('/').last;

      print('Preparando archivo comprimido para subir:');
      print('Nombre del archivo: $fileName');
      print('Tamaño original: ${await file.length()} bytes');
      print('Tamaño comprimido: ${await compressedFile.length()} bytes');

      // Crear FormData con el archivo comprimido
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          compressedFile.path,
          filename: fileName,
          contentType: MediaType('image', 'jpeg'),
        ),
      });

      final response = await dio.post(
        '/upload/image',
        data: formData,
        queryParameters: {'folder': 'clients'},
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return response.data['url'];
      }

      throw Exception('Error al subir imagen: ${response.data['message']}');
    } on DioException catch (e) {
      print('Error DioException detallado:');
      print('Type: ${e.type}');
      print('Message: ${e.message}');
      print('Response: ${e.response?.data}');
      throw Exception(
          'Error al subir imagen: ${e.message ?? "Error de conexión"}');
    } catch (e) {
      print('Error general al subir imagen:');
      print(e);
      throw Exception('Error al subir imagen: $e');
    }
  }

// Método para comprimir la imagen
  Future<File> compressImage(File file) async {
    try {
      final img.Image? image = img.decodeImage(await file.readAsBytes());
      if (image == null) throw Exception('No se pudo decodificar la imagen');

      // Reducir el tamaño si es necesario
      img.Image resized = image;
      if (image.width > 1024) {
        resized = img.copyResize(image, width: 1024);
      }

      // Comprimir y guardar
      final compressed = img.encodeJpg(resized, quality: 85);
      final tempDir = Directory.systemTemp;
      final tempFile = File(
          '${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await tempFile.writeAsBytes(compressed);

      return tempFile;
    } catch (e) {
      print('Error al comprimir imagen: $e');
      return file; // Retornar archivo original si hay error
    }
  }

  Future<String> updateClientImage(String clientId, File file) async {
    try {
      final token = await localStorage.getToken();

      // Verificar que el archivo existe y es accesible
      if (!file.existsSync()) {
        throw Exception('El archivo no existe');
      }

      print('Preparando archivo para subir:');
      print('Path: ${file.path}');
      print('Tamaño: ${await file.length()} bytes');

      // Crear el FormData con el archivo
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last,
          contentType: MediaType('image', 'jpeg'),
        ),
      });

      print('Enviando petición al servidor...');
      final response = await dio.patch(
        '/upload/image', // Usamos el nuevo endpoint centralizado
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      print('Respuesta del servidor:');
      print(response.data);

      if (response.statusCode != 200) {
        throw Exception('Error al subir imagen: ${response.data['message']}');
      }

      if (response.data['url'] == null) {
        throw Exception('No se recibió URL de imagen');
      }

      return response.data['url'];
    } catch (e) {
      print('Error detallado al actualizar imagen:');
      print(e);
      throw Exception('Error al actualizar imagen: $e');
    }
  }
}
