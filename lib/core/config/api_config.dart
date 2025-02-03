import 'package:dio/dio.dart';

class ApiConfig {
  static Dio createDio(String baseUrl) {
    final dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 3),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      validateStatus: (status) => status != null && status < 500,
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        // Solo log esencial
        if (options.data != null) {
          print('Request [${options.method}] ${options.uri}');
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        // Solo log de respuesta exitosa si es necesario
        if (response.statusCode != 200) {
          print(
              'Response [${response.statusCode}] ${response.requestOptions.uri}');
        }
        return handler.next(response);
      },
      onError: (error, handler) async {
        print(
            'Error [${error.response?.statusCode}] ${error.requestOptions.uri}');
        if (error.response?.data != null) {
          print('Error data: ${error.response?.data}');
        }

        var retryCount = error.requestOptions.extra['retryCount'] ?? 0;

        if (_shouldRetry(error) && retryCount < 3) {
          retryCount++;
          await Future.delayed(Duration(seconds: retryCount));

          try {
            final response = await dio
                .fetch(error.requestOptions..extra['retryCount'] = retryCount);
            return handler.resolve(response);
          } catch (e) {
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
        (error.response?.statusCode == 401);
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
        return 'Error de conexión';
    }
  }

  static String _handleErrorResponse(Response? response) {
    if (response == null) return 'Error desconocido';

    final message = response.data?['message'];
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
      default:
        return 'Error del servidor';
    }
  }
}
