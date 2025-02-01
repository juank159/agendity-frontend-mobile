// import 'package:dio/dio.dart';

// class ApiConfig {
//   static Dio createDio(String baseUrl) {
//     return Dio(BaseOptions(
//       baseUrl: baseUrl,
//       connectTimeout: const Duration(seconds: 5),
//       receiveTimeout: const Duration(seconds: 3),
//       headers: {
//         'Content-Type': 'application/json',
//         'Accept': 'application/json',
//       },
//     ))
//       ..interceptors.add(LogInterceptor(
//         request: true,
//         responseBody: true,
//         requestBody: true,
//         requestHeader: true,
//       ));
//   }
// }

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

    // Agregar interceptor personalizado para logging y manejo de errores
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        print('\n*** Request ***');
        print('uri: ${options.uri}');
        print('method: ${options.method}');
        print('responseType: ${options.responseType}');
        print('followRedirects: ${options.followRedirects}');
        print('persistentConnection: ${options.persistentConnection}');
        print('connectTimeout: ${options.connectTimeout}');
        print('sendTimeout: ${options.sendTimeout}');
        print('receiveTimeout: ${options.receiveTimeout}');
        print(
            'receiveDataWhenStatusError: ${options.receiveDataWhenStatusError}');
        print('extra: ${options.extra}');
        print('headers:');
        options.headers.forEach((key, value) {
          print(' $key: $value');
        });
        if (options.data != null) {
          print('data:');
          print(options.data);
        }
        print('');
        return handler.next(options);
      },
      onResponse: (response, handler) {
        print('\n*** Response ***');
        print('uri: ${response.requestOptions.uri}');
        print('statusCode: ${response.statusCode}');
        print('headers:');
        response.headers.forEach((name, values) {
          print(' $name: ${values.join(', ')}');
        });
        print('Response Text:');
        print(response.data);
        print('');
        return handler.next(response);
      },
      onError: (error, handler) async {
        print('\n*** Error ***');
        print('uri: ${error.requestOptions.uri}');
        print('type: ${error.type}');
        if (error.response != null) {
          print('statusCode: ${error.response?.statusCode}');
          print('data: ${error.response?.data}');
        }
        print('message: ${error.message}');
        print('');

        // Obtener el conteo de reintentos actual
        var retryCount = error.requestOptions.extra['retryCount'] ?? 0;

        // Verificar si debemos reintentar
        if (_shouldRetry(error) && retryCount < 3) {
          retryCount++;
          print('Reintentando petición ($retryCount/3)...');

          // Esperar antes de reintentar (backoff exponencial)
          await Future.delayed(Duration(seconds: retryCount));

          try {
            final response = await dio
                .fetch(error.requestOptions..extra['retryCount'] = retryCount);
            return handler.resolve(response);
          } catch (e) {
            // Crear un nuevo DioException con el mensaje personalizado
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

        // Crear un nuevo DioException con el mensaje personalizado
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
        (error.response?.statusCode ==
            401); // Reintentar en caso de token expirado
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
        return 'Error de conexión: ${error.message}';
    }
  }

  static String _handleErrorResponse(Response? response) {
    if (response == null) return 'Error desconocido';

    switch (response.statusCode) {
      case 400:
        return 'Solicitud incorrecta: ${response.data?['message'] ?? 'Error de validación'}';
      case 401:
        return 'No autorizado: Por favor inicie sesión nuevamente';
      case 403:
        return 'Acceso denegado';
      case 404:
        return 'Recurso no encontrado';
      case 409:
        return 'Conflicto con el recurso existente';
      case 422:
        return 'Error de validación: ${response.data?['message'] ?? 'Datos inválidos'}';
      case 429:
        return 'Demasiadas solicitudes. Por favor, intente más tarde';
      default:
        return 'Error del servidor: ${response.statusCode}';
    }
  }
}
