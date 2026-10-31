import 'dart:io';

import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image/image.dart' as img;

/// Lo que de clientes sigue yendo directo al servidor (10.02): la foto
/// (`POST /upload/image`, solo con conexión) y la lectura de un cliente para
/// deshacer en local una operación rechazada (`GET /clients/:id`). Altas,
/// ediciones, borrados e importación van por la bandeja de salida
/// (`client.*`, `SyncEngine`) y las lecturas, a la base local. Los errores
/// salen como `DioException` (los traduce `safeCall`/`ErrorMapper`).
abstract class ClientsRemoteDataSource {
  /// `GET /clients/:id`: el cliente con la forma de la API.
  Future<Map<String, dynamic>> fetchClient(String id);

  /// `POST /upload/image?folder=clients` (multipart `file`, JPEG comprimido).
  /// Responde `{url, message}`.
  Future<String> uploadImage(String filePath);
}

class ClientsRemoteDataSourceImpl implements ClientsRemoteDataSource {
  /// Subidas: timeout largo por petición (el Dio es
  /// compartido y no se mutan sus `options`).
  static const Duration longTimeout = Duration(seconds: 60);

  /// Ancho máximo de la foto antes de subirla.
  static const int maxImageWidth = 1024;

  static const unreadableImage = 'No se pudo leer la imagen elegida';

  final Dio _dio;

  /// Debe ser el Dio `tag: apiClientTag` (token y errores del núcleo).
  ClientsRemoteDataSourceImpl(this._dio);

  @override
  Future<Map<String, dynamic>> fetchClient(String id) async {
    final response = await _dio.get<Map<String, dynamic>>('/clients/$id');
    return response.data ?? const {};
  }

  @override
  Future<String> uploadImage(String filePath) async {
    final original = File(filePath);
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
