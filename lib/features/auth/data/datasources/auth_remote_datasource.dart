import 'package:dio/dio.dart';
import 'package:login_signup/core/errors/exceptions.dart';
import 'package:login_signup/features/auth/data/models/user_model.dart';
import 'dart:io'; // Importar para SocketException
import '../../../../shared/local_storage/local_storage.dart';

class AuthRemoteDataSource {
  final Dio _dio;
  final LocalStorage _localStorage;

  AuthRemoteDataSource({
    required Dio dio,
    required LocalStorage localStorage,
  })  : _dio = dio,
        _localStorage = localStorage;

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        return response.data;
      }
      throw ServerException(
        message: response.data['message'] ?? 'Error desconocido en el servidor',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      print(
          'AuthRemoteDataSource: DioException capturada. Tipo: ${e.type}, Error subyacente: ${e.error.runtimeType}'); // Debug
      if (e.response != null) {
        print(
            'AuthRemoteDataSource: DioException con respuesta del servidor. Status: ${e.response?.statusCode}'); // Debug
        // El servidor respondió con un error (ej. 401, 400, 500)
        throw ServerException(
          message: e.response?.data['message'] ??
              'Error del servidor: ${e.response?.statusCode}',
          statusCode: e.response?.statusCode,
        );
      } else {
        print(
            'AuthRemoteDataSource: DioException sin respuesta del servidor (error de conexión).'); // Debug
        // Error de conexión (sin respuesta del servidor)
        // Verificar si es un "Connection refused" de forma más robusta
        bool isConnectionRefused = false;
        if (e.type == DioExceptionType.connectionError) {
          if (e.error is SocketException) {
            final socketException = e.error as SocketException;
            print(
                'AuthRemoteDataSource: SocketException detectada. Mensaje: ${socketException.message}, osError: ${socketException.osError?.errorCode}'); // Debug
            if (socketException.osError != null &&
                (socketException.osError!.errorCode == 111 || // Linux/Android
                    socketException.osError!.errorCode == 61 || // macOS/iOS
                    socketException.osError!.errorCode == 10061 // Windows
                )) {
              isConnectionRefused = true;
            }
          } else if (e.error is String) {
            // Si e.error es una cadena, verificar si contiene el mensaje de "Connection refused"
            final errorMessage = e.error.toString().toLowerCase();
            if (errorMessage.contains('connection refused') ||
                errorMessage.contains('errno = 111')) {
              isConnectionRefused = true;
            }
          }
        }

        if (isConnectionRefused) {
          print(
              'AuthRemoteDataSource: Connection refused detectado por código de error o mensaje.'); // Debug
          throw ServerException(
            message:
                'Error interno del servidor. Por favor, inténtelo de nuevo más tarde.',
            statusCode: null,
          );
        }

        print('AuthRemoteDataSource: Lanzando error de red genérico.'); // Debug
        // Error de red genérico (ej. no hay internet, DNS falló, etc.)
        throw ServerException(
          message: 'Error de red. Verifique su conexión a internet.',
          statusCode: null,
        );
      }
    }
  }

  Future<void> signOut() async {
    try {
      await _localStorage.deleteToken();
    } catch (e) {
      throw Exception('Error al cerrar sesión: ${e.toString()}');
    }
  }

  Future<UserModel> register({
    required String name,
    required String lastname,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/register/owner', // ← CORREGIDO: Ruta correcta
        data: {
          'name': name,
          'lastname': lastname,
          'email': email,
          'phone': phone,
          'password': password,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Guardar token si existe
        final token = response.data['token'];
        if (token != null) {
          await _localStorage.saveToken(token);
        }

        // Asegurar la estructura correcta para fromJson
        final userData = {
          'user':
              response.data['user'] // Aseguramos que sea la estructura correcta
        };

        return UserModel.fromJson(userData);
      }

      throw ServerException(
        message: response.data['message'] ?? 'Error desconocido en el registro',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      if (e.response != null) {
        throw ServerException(
          message: e.response?.data['message'] ??
              'Error del servidor: ${e.response?.statusCode}',
          statusCode: e.response?.statusCode,
        );
      } else {
        bool isConnectionRefused = false;
        if (e.type == DioExceptionType.connectionError) {
          if (e.error is SocketException) {
            final socketException = e.error as SocketException;
            if (socketException.osError != null &&
                (socketException.osError!.errorCode == 111 ||
                    socketException.osError!.errorCode == 61 ||
                    socketException.osError!.errorCode == 10061)) {
              isConnectionRefused = true;
            }
          } else if (e.error is String) {
            final errorMessage = e.error.toString().toLowerCase();
            if (errorMessage.contains('connection refused') ||
                errorMessage.contains('errno = 111')) {
              isConnectionRefused = true;
            }
          }
        }

        if (isConnectionRefused) {
          throw ServerException(
            message:
                'Error interno del servidor. Por favor, inténtelo de nuevo más tarde.',
            statusCode: null,
          );
        }
        throw ServerException(
          message: 'Error de red. Verifique su conexión a internet.',
          statusCode: null,
        );
      }
    }
  }

  // ← CORREGIDO: Método para solicitar código de verificación
  Future<void> requestVerificationCode(
      {required String email, bool isNewUser = true}) async {
    try {
      final response = await _dio.post(
        '/auth/verify/request-code', // ← CORREGIDO: Ruta correcta
        data: {
          'email': email,
          'isNewUser': isNewUser, // ← AGREGADO: Parámetro necesario
        },
      );

      if (response.statusCode! < 200 || response.statusCode! >= 300) {
        throw ServerException(
          message: response.data['message'] ??
              'Error al solicitar código de verificación',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw ServerException(
          message: e.response?.data?['message'] ??
              'Error de conexión al solicitar código',
          statusCode: e.response?.statusCode,
        );
      } else {
        bool isConnectionRefused = false;
        if (e.type == DioExceptionType.connectionError) {
          if (e.error is SocketException) {
            final socketException = e.error as SocketException;
            if (socketException.osError != null &&
                (socketException.osError!.errorCode == 111 ||
                    socketException.osError!.errorCode == 61 ||
                    socketException.osError!.errorCode == 10061)) {
              isConnectionRefused = true;
            }
          } else if (e.error is String) {
            final errorMessage = e.error.toString().toLowerCase();
            if (errorMessage.contains('connection refused') ||
                errorMessage.contains('errno = 111')) {
              isConnectionRefused = true;
            }
          }
        }

        if (isConnectionRefused) {
          throw ServerException(
            message:
                'Error interno del servidor. Por favor, inténtelo de nuevo más tarde.',
            statusCode: null,
          );
        }
        throw ServerException(
            message: 'Error de red. Verifique su conexión a internet.');
      }
    }
  }

  // ← CORREGIDO: Método para verificar el email
  Future<bool> verifyEmail(
      {required String email, required String code}) async {
    try {
      final response = await _dio.post(
        '/auth/verify/email', // ← CORREGIDO: Ruta correcta
        data: {
          'email': email,
          'code': code,
        },
      );

      if (response.statusCode! >= 200 && response.statusCode! < 300) {
        return response.data['is_verified'] ?? true;
      }

      throw ServerException(
        message: response.data['message'] ?? 'Error al verificar email',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      if (e.response != null) {
        throw ServerException(
          message: e.response?.data?['message'] ??
              'Error de conexión al verificar email',
          statusCode: e.response?.statusCode,
        );
      } else {
        bool isConnectionRefused = false;
        if (e.type == DioExceptionType.connectionError) {
          if (e.error is SocketException) {
            final socketException = e.error as SocketException;
            if (socketException.osError != null &&
                (socketException.osError!.errorCode == 111 ||
                    socketException.osError!.errorCode == 61 ||
                    socketException.osError!.errorCode == 10061)) {
              isConnectionRefused = true;
            }
          } else if (e.error is String) {
            final errorMessage = e.error.toString().toLowerCase();
            if (errorMessage.contains('connection refused') ||
                errorMessage.contains('errno = 111')) {
              isConnectionRefused = true;
            }
          }
        }

        if (isConnectionRefused) {
          throw ServerException(
            message:
                'Error interno del servidor. Por favor, inténtelo de nuevo más tarde.',
            statusCode: null,
          );
        }
        throw ServerException(
            message: 'Error de red. Verifique su conexión a internet.');
      }
    }
  }

  Future<void> requestPasswordReset({required String email}) async {
    try {
      final response = await _dio.post(
        '/auth/forgot-password',
        data: {'email': email},
      );

      if (response.statusCode! < 200 || response.statusCode! >= 300) {
        throw ServerException(
          message:
              response.data['message'] ?? 'Error al solicitar recuperación',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw ServerException(
          message: e.response?.data?['message'] ?? 'Error de conexión',
          statusCode: e.response?.statusCode,
        );
      } else {
        bool isConnectionRefused = false;
        if (e.type == DioExceptionType.connectionError) {
          if (e.error is SocketException) {
            final socketException = e.error as SocketException;
            if (socketException.osError != null &&
                (socketException.osError!.errorCode == 111 ||
                    socketException.osError!.errorCode == 61 ||
                    socketException.osError!.errorCode == 10061)) {
              isConnectionRefused = true;
            }
          } else if (e.error is String) {
            final errorMessage = e.error.toString().toLowerCase();
            if (errorMessage.contains('connection refused') ||
                errorMessage.contains('errno = 111')) {
              isConnectionRefused = true;
            }
          }
        }

        if (isConnectionRefused) {
          throw ServerException(
            message:
                'Error interno del servidor. Por favor, inténtelo de nuevo más tarde.',
            statusCode: null,
          );
        }
        throw ServerException(
            message: 'Error de red. Verifique su conexión a internet.');
      }
    }
  }

  // Future<bool> resetPassword({
  //   required String email,
  //   required String code,
  //   required String newPassword,
  // }) async {
  //   try {
  //     final response = await _dio.post(
  //       '/auth/reset-password',
  //       data: {
  //         'email': email,
  //         'code': code,
  //         'new_password': newPassword,
  //       },
  //     );

  //     if (response.statusCode! >= 200 && response.statusCode! < 300) {
  //       return true;
  //     }

  //     throw ServerException(
  //       message: response.data['message'] ?? 'Error al restablecer contraseña',
  //       statusCode: response.statusCode,
  //     );
  //   } on DioException catch (e) {
  //     if (e.response != null) {
  //       throw ServerException(
  //         message: e.response?.data?['message'] ?? 'Error de conexión',
  //         statusCode: e.response?.statusCode,
  //       );
  //     } else {
  //       bool isConnectionRefused = false;
  //       if (e.type == DioExceptionType.connectionError) {
  //         if (e.error is SocketException) {
  //           final socketException = e.error as SocketException;
  //           if (socketException.osError != null &&
  //               (socketException.osError!.errorCode == 111 ||
  //                   socketException.osError!.errorCode == 61 ||
  //                   socketException.osError!.errorCode == 10061)) {
  //             isConnectionRefused = true;
  //           }
  //         } else if (e.error is String) {
  //           final errorMessage = e.error.toString().toLowerCase();
  //           if (errorMessage.contains('connection refused') ||
  //               errorMessage.contains('errno = 111')) {
  //             isConnectionRefused = true;
  //           }
  //         }
  //       }

  //       if (isConnectionRefused) {
  //         throw ServerException(
  //           message:
  //               'Error interno del servidor. Por favor, inténtelo de nuevo más tarde.',
  //           statusCode: null,
  //         );
  //       }
  //       throw ServerException(
  //           message: 'Error de red. Verifique su conexión a internet.');
  //     }
  //   }
  // }

  Future<bool> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/reset-password',
        data: {
          'email': email,
          'code': code,
          'newPassword':
              newPassword, // ← CORREGIDO: usar 'newPassword' en lugar de 'new_password'
        },
      );

      if (response.statusCode! >= 200 && response.statusCode! < 300) {
        return true;
      }

      // ← CORREGIDO: Manejo de mensajes que pueden ser string o lista
      String errorMessage = 'Error al restablecer contraseña';
      if (response.data['message'] != null) {
        final message = response.data['message'];
        if (message is List) {
          // Si es una lista, tomar el primer mensaje o unirlos
          errorMessage =
              message.isNotEmpty ? message.first.toString() : errorMessage;
        } else {
          errorMessage = message.toString();
        }
      }

      throw ServerException(
        message: errorMessage,
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      if (e.response != null) {
        // ← CORREGIDO: Manejo de mensajes de error que pueden ser lista
        String errorMessage = 'Error de conexión';
        if (e.response?.data?['message'] != null) {
          final message = e.response!.data['message'];
          if (message is List) {
            // Si es una lista, tomar el primer mensaje
            errorMessage =
                message.isNotEmpty ? message.first.toString() : errorMessage;
          } else {
            errorMessage = message.toString();
          }
        }

        throw ServerException(
          message: errorMessage,
          statusCode: e.response?.statusCode,
        );
      } else {
        bool isConnectionRefused = false;
        if (e.type == DioExceptionType.connectionError) {
          if (e.error is SocketException) {
            final socketException = e.error as SocketException;
            if (socketException.osError != null &&
                (socketException.osError!.errorCode == 111 ||
                    socketException.osError!.errorCode == 61 ||
                    socketException.osError!.errorCode == 10061)) {
              isConnectionRefused = true;
            }
          } else if (e.error is String) {
            final errorMessage = e.error.toString().toLowerCase();
            if (errorMessage.contains('connection refused') ||
                errorMessage.contains('errno = 111')) {
              isConnectionRefused = true;
            }
          }
        }

        if (isConnectionRefused) {
          throw ServerException(
            message:
                'Error interno del servidor. Por favor, inténtelo de nuevo más tarde.',
            statusCode: null,
          );
        }
        throw ServerException(
            message: 'Error de red. Verifique su conexión a internet.');
      }
    }
  }

  // En AuthRemoteDataSource, agregar este método específico para reset password
  Future<void> requestPasswordResetCode({required String email}) async {
    try {
      final response = await _dio.post(
        '/auth/verify/request-code', // Usar el mismo endpoint
        data: {
          'email': email,
          'isNewUser': false, // ← IMPORTANTE: false para reset password
        },
      );

      if (response.statusCode! < 200 || response.statusCode! >= 300) {
        throw ServerException(
          message: response.data['message'] ??
              'Error al solicitar código de recuperación',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      // Mismo manejo de errores que los otros métodos...
      if (e is DioException) {
        if (e.response != null) {
          throw ServerException(
            message: e.response?.data?['message'] ?? 'Error de conexión',
            statusCode: e.response?.statusCode,
          );
        } else {
          bool isConnectionRefused = false;
          if (e.type == DioExceptionType.connectionError) {
            if (e.error is SocketException) {
              final socketException = e.error as SocketException;
              if (socketException.osError != null &&
                  (socketException.osError!.errorCode == 111 ||
                      socketException.osError!.errorCode == 61 ||
                      socketException.osError!.errorCode == 10061)) {
                isConnectionRefused = true;
              }
            } else if (e.error is String) {
              final errorMessage = e.error.toString().toLowerCase();
              if (errorMessage.contains('connection refused') ||
                  errorMessage.contains('errno = 111')) {
                isConnectionRefused = true;
              }
            }
          }

          if (isConnectionRefused) {
            throw ServerException(
              message:
                  'Error interno del servidor. Por favor, inténtelo de nuevo más tarde.',
              statusCode: null,
            );
          }
          throw ServerException(
              message: 'Error de red. Verifique su conexión a internet.');
        }
      }
      throw ServerException(message: e.toString());
    }
  }
}
