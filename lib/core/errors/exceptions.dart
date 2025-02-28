// lib/core/error/exceptions.dart
class ServerException implements Exception {
  final String message;
  final int? statusCode;

  ServerException({
    this.message = 'Se produjo un error en el servidor',
    this.statusCode,
  });

  @override
  String toString() => 'ServerException: $message (Code: $statusCode)';
}

class CacheException implements Exception {
  final String message;

  CacheException({this.message = 'Error en la caché'});

  @override
  String toString() => 'CacheException: $message';
}

class NotFoundException implements Exception {
  final String message;

  NotFoundException([this.message = 'Recurso no encontrado']);

  @override
  String toString() => 'NotFoundException: $message';
}
