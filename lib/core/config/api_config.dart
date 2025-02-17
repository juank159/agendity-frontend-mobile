import 'package:dio/dio.dart';

class ApiConfig {
  static Dio createDio(String baseUrl) {
    final dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout:
          const Duration(seconds: 30), // Aumentado para mejor estabilidad
      receiveTimeout:
          const Duration(seconds: 30), // Aumentado para mejor estabilidad
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      validateStatus: (status) {
        // Permitir códigos 500 para manejarlos manualmente
        return status != null && status < 600;
      },
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        print('=== REQUEST ===');
        print('URL: ${options.uri}');
        print('Method: ${options.method}');
        print('Headers: ${options.headers}');
        print('Query Parameters: ${options.queryParameters}');
        print('Data: ${options.data}');
        return handler.next(options);
      },
      onResponse: (response, handler) {
        print('=== RESPONSE ===');
        print('Status code: ${response.statusCode}');
        print('Headers: ${response.headers}');
        print('Data: ${response.data}');
        return handler.next(response);
      },
      onError: (error, handler) async {
        print('\n=== ERROR ===');
        print('Error Type: ${error.type}');
        print(
            'Error [${error.response?.statusCode}] ${error.requestOptions.uri}');
        print('Request Headers: ${error.requestOptions.headers}');
        if (error.response?.data != null) {
          print('Error data: ${error.response?.data}');
        }

        var retryCount = error.requestOptions.extra['retryCount'] ?? 0;

        if (_shouldRetry(error) && retryCount < 3) {
          print('Reintentando petición - Intento ${retryCount + 1}');
          retryCount++;
          await Future.delayed(Duration(seconds: retryCount));

          try {
            final opts = error.requestOptions..extra['retryCount'] = retryCount;
            final response = await dio.fetch(opts);
            print('Reintento exitoso');
            return handler.resolve(response);
          } catch (e) {
            print('Reintento fallido: $e');
            return handler.next(
              DioException(
                requestOptions: error.requestOptions,
                error: _getErrorMessage(error),
                type: error.type,
                response: error.response,
              ),
            );
          }
        }

        return handler.next(
          DioException(
            requestOptions: error.requestOptions,
            error: _getErrorMessage(error),
            type: error.type,
            response: error.response,
          ),
        );
      },
    ));

    return dio;
  }

  static bool _shouldRetry(DioException error) {
    return error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError ||
        (error.response?.statusCode == 401) ||
        (error.response?.statusCode ==
            500); // Agregado para reintentar en error 500
  }

  static String _getErrorMessage(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Tiempo de espera agotado en la conexión';
      case DioExceptionType.badResponse:
        return _handleErrorResponse(error.response);
      case DioExceptionType.cancel:
        return 'Solicitud cancelada';
      default:
        if (error.error != null && error.error.toString().isNotEmpty) {
          return error.error.toString();
        }
        return 'Error de conexión';
    }
  }

  static String _handleErrorResponse(Response? response) {
    if (response == null) return 'Error desconocido';

    final message = response.data is Map ? response.data['message'] : null;
    switch (response.statusCode) {
      case 400:
        return message ?? 'Error de validación';
      case 401:
        return 'Sesión expirada';
      case 403:
        return 'Acceso denegado';
      case 404:
        return 'Recurso no encontrado';
      case 409:
        return message ?? 'Conflicto con recurso existente';
      case 422:
        return message ?? 'Datos inválidos';
      case 429:
        return 'Demasiadas solicitudes';
      case 500:
        return message ?? 'Error interno del servidor';
      default:
        return message ?? 'Error del servidor';
    }
  }
}
