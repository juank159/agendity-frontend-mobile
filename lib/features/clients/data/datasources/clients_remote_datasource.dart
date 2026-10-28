import 'dart:io';

import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image/image.dart' as img;
import 'package:login_signup/features/clients/data/models/client_import_result_model.dart';
import 'package:login_signup/features/clients/data/models/client_model.dart';
import 'package:login_signup/features/clients/data/models/client_page_model.dart';
import 'package:login_signup/features/clients/domain/entities/clients_query.dart';
import 'package:login_signup/features/clients/domain/failures/client_failures.dart';

/// Rutas `/clients` y `POST /upload/image`. Owner y Employee (los clientes son
/// del negocio). Los errores (400/403/404/409, red) salen como `DioException`
/// y los traduce `safeCall` en el repositorio.
abstract class ClientsRemoteDataSource {
  /// `GET /clients` con paginación, filtros y orden.
  Future<ClientPageModel> getClients(ClientsQuery query);

  /// `GET /clients/all`: todos, sin paginar (con sus citas y reseñas).
  Future<List<ClientModel>> getAllClients();

  /// `GET /clients/:id`.
  Future<ClientModel> getClientById(String id);

  /// `POST /clients`. Responde 201 con el cliente creado.
  Future<ClientModel> createClient(ClientModel client);

  /// `PATCH /clients/:id`. Responde 200 con el cliente.
  Future<ClientModel> updateClient(String id, ClientModel client);

  /// `DELETE /clients/:id`. Responde 200 sin cuerpo.
  Future<void> deleteClient(String id);

  /// `POST /clients/batch`. Responde 201 con el resultado parcial.
  Future<ClientImportResultModel> importClients(List<ClientModel> clients);

  /// `POST /upload/image?folder=clients` (multipart `file`, JPEG comprimido).
  /// Responde `{url, message}`. Archivo inexistente →
  /// `InvalidClientDataFailure` sin llamar al backend.
  Future<String> uploadImage(String filePath);
}

class ClientsRemoteDataSourceImpl implements ClientsRemoteDataSource {
  /// Subidas e importación en lote: timeout largo por petición (el Dio es
  /// compartido y no se mutan sus `options`).
  static const Duration longTimeout = Duration(seconds: 60);

  /// Ancho máximo de la foto antes de subirla.
  static const int maxImageWidth = 1024;

  static const unreadableImage = 'No se pudo leer la imagen elegida';

  final Dio _dio;

  /// Debe ser el Dio `tag: apiClientTag` (token y errores del núcleo).
  ClientsRemoteDataSourceImpl(this._dio);

  @override
  Future<ClientPageModel> getClients(ClientsQuery query) async {
    final search = query.normalizedSearch;
    final response = await _dio.get<Map<String, dynamic>>(
      '/clients',
      queryParameters: {
        'page': query.page,
        'limit': query.limit,
        if (search != null) 'search': search,
        'sortBy': query.sortBy.apiValue,
        'sortOrder': query.direction.apiValue,
        'status': query.status.apiValue,
        'source': query.source.apiValue,
      },
    );
    return ClientPageModel.fromJson(response.data!);
  }

  @override
  Future<List<ClientModel>> getAllClients() async {
    final response = await _dio.get<List<dynamic>>('/clients/all');
    return response.data!
        .whereType<Map<String, dynamic>>()
        .map(ClientModel.fromJson)
        .toList();
  }

  @override
  Future<ClientModel> getClientById(String id) async {
    final response = await _dio.get<Map<String, dynamic>>('/clients/$id');
    return ClientModel.fromJson(response.data!);
  }

  @override
  Future<ClientModel> createClient(ClientModel client) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/clients',
      data: client.toJson(),
    );
    return ClientModel.fromJson(response.data!);
  }

  @override
  Future<ClientModel> updateClient(String id, ClientModel client) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/clients/$id',
      data: client.toJson(),
    );
    return ClientModel.fromJson(response.data!);
  }

  @override
  Future<void> deleteClient(String id) async {
    await _dio.delete<void>('/clients/$id');
  }

  @override
  Future<ClientImportResultModel> importClients(
      List<ClientModel> clients) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/clients/batch',
      data: {'clients': clients.map((c) => c.toImportJson()).toList()},
      options: Options(sendTimeout: longTimeout, receiveTimeout: longTimeout),
    );
    return ClientImportResultModel.fromJson(response.data!);
  }

  @override
  Future<String> uploadImage(String filePath) async {
    final original = File(filePath);
    if (!original.existsSync()) {
      throw const InvalidClientDataFailure(message: unreadableImage);
    }
    final file = await _compress(original);
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        file.path,
        filename: file.uri.pathSegments.last,
        contentType: MediaType('image', 'jpeg'),
      ),
    });
    final response = await _dio.post<Map<String, dynamic>>(
      '/upload/image',
      data: formData,
      queryParameters: {'folder': 'clients'},
      options: Options(sendTimeout: longTimeout, receiveTimeout: longTimeout),
    );
    final url = response.data?['url'];
    if (url is! String || url.isEmpty) {
      throw const FormatException('La subida no devolvió la URL de la imagen');
    }
    return url;
  }

  /// JPEG de calidad 85 y como mucho [maxImageWidth] px de ancho, en un
  /// archivo temporal. Si no se puede decodificar, el original.
  static Future<File> _compress(File file) async {
    final image = img.decodeImage(await file.readAsBytes());
    if (image == null) return file;
    final resized = image.width > maxImageWidth
        ? img.copyResize(image, width: maxImageWidth)
        : image;
    final compressed = File('${Directory.systemTemp.path}/client_'
        '${DateTime.now().millisecondsSinceEpoch}.jpg');
    return compressed.writeAsBytes(img.encodeJpg(resized, quality: 85));
  }
}
