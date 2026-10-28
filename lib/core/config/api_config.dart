import 'package:dio/dio.dart';
import 'package:login_signup/core/network/interceptors/retry_interceptor.dart';
import 'package:login_signup/core/utils/app_logger.dart';

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
        // Solo en debug y nunca headers ni cuerpo (llevan el token y la contraseña).
        AppLogger.debug('=== REQUEST === ${options.method} ${options.uri}');
        return handler.next(options);
      },
      onResponse: (response, handler) {
        // Sin headers ni cuerpo: la respuesta del login trae el token.
        AppLogger.debug('=== RESPONSE === ${response.statusCode} '
            '${response.requestOptions.method} ${response.requestOptions.uri}');
        return handler.next(response);
      },
      onError: (error, handler) async {
        // Sin el cuerpo: puede traer datos personales.
        AppLogger.debug('=== ERROR === ${error.type} '
            '[${error.response?.statusCode}] ${error.requestOptions.uri}');

        var retryCount = error.requestOptions.extra['retryCount'] ?? 0;

        if (RetryInterceptor.shouldRetry(error) && retryCount < 3) {
          AppLogger.debug('Reintentando petición - Intento ${retryCount + 1}');
          retryCount++;
          await Future.delayed(Duration(seconds: retryCount));

          try {
            final opts = error.requestOptions..extra['retryCount'] = retryCount;
            final response = await dio.fetch(opts);
            return handler.resolve(response);
          } catch (e) {
            AppLogger.error('Reintento fallido', e);
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
