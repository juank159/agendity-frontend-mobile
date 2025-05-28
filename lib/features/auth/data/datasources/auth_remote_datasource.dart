// import 'package:dio/dio.dart';
// import 'package:login_signup/core/errors/exceptions.dart';
// import 'package:login_signup/features/auth/data/models/user_model.dart';
// import '../../../../shared/local_storage/local_storage.dart';

// class AuthRemoteDataSource {
//   final Dio _dio;
//   final LocalStorage _localStorage;

//   AuthRemoteDataSource({
//     required Dio dio,
//     required LocalStorage localStorage,
//   })  : _dio = dio,
//         _localStorage = localStorage;

//   Future<Map<String, dynamic>> login({
//     required String email,
//     required String password,
//   }) async {
//     try {
//       final response = await _dio.post(
//         '/auth/login',
//         data: {
//           'email': email,
//           'password': password,
//         },
//       );

//       if (response.statusCode == 200) {
//         return response.data;
//       }

//       throw Exception('Error en inicio de sesión');
//     } catch (e) {
//       throw Exception('Error en inicio de sesión: ${e.toString()}');
//     }
//   }

//   Future<void> signOut() async {
//     try {
//       await _localStorage.deleteToken();
//     } catch (e) {
//       throw Exception('Error al cerrar sesión: ${e.toString()}');
//     }
//   }

//   Future<UserModel> register({
//     required String name,
//     required String lastname,
//     required String email,
//     required String phone,
//     required String password,
//   }) async {
//     try {
//       final response = await _dio.post(
//         '/auth/register/owner',
//         data: {
//           'name': name,
//           'lastname': lastname,
//           'email': email,
//           'phone': phone,
//           'password': password,
//         },
//       );

//       if (response.statusCode == 200 || response.statusCode == 201) {
//         // Guardar token
//         final token = response.data['token'];
//         if (token != null) {
//           await _localStorage.saveToken(token);
//         }

//         // Asegurar la estructura correcta para fromJson
//         // Tu UserModel.fromJson espera que los datos estén dentro de una clave 'user'
//         final userData = {
//           'user':
//               response.data['user'] // Aseguramos que sea la estructura correcta
//         };

//         // Convertir y devolver el modelo de usuario
//         return UserModel.fromJson(userData);
//       } else {
//         throw ServerException(
//           message: response.data['message'] ?? 'Error al registrar usuario',
//           statusCode: response.statusCode,
//         );
//       }
//     } on DioException catch (e) {
//       throw ServerException(
//         message: e.response?.data?['message'] ?? 'Error de conexión',
//         statusCode: e.response?.statusCode,
//       );
//     } catch (e) {
//       throw ServerException(message: e.toString());
//     }
//   }

//   Future<void> requestVerificationCode({required String email}) async {
//     try {
//       final response = await _dio.post(
//         '/auth/verify/request-code',
//         data: {'email': email},
//       );

//       if (response.statusCode! < 200 || response.statusCode! >= 300) {
//         throw ServerException(
//           message: response.data['message'] ?? 'Error al solicitar código',
//           statusCode: response.statusCode,
//         );
//       }
//     } catch (e) {
//       if (e is DioException) {
//         throw ServerException(
//           message: e.response?.data?['message'] ?? 'Error de conexión',
//           statusCode: e.response?.statusCode,
//         );
//       }
//       throw ServerException(message: e.toString());
//     }
//   }

//   Future<bool> verifyEmail(
//       {required String email, required String code}) async {
//     try {
//       final response = await _dio.post(
//         '/auth/verify/email',
//         data: {
//           'email': email,
//           'code': code,
//         },
//       );

//       // Considera cualquier código 2xx como éxito
//       if (response.statusCode! >= 200 && response.statusCode! < 300) {
//         return response.data['is_verified'] ?? false;
//       }

//       throw ServerException(
//         message: response.data['message'] ?? 'Error de verificación',
//         statusCode: response.statusCode,
//       );
//     } catch (e) {
//       if (e is DioException) {
//         // Solo manejar errores reales (4xx, 5xx)
//         if (e.response?.statusCode != null && e.response!.statusCode! >= 400) {
//           throw ServerException(
//             message: e.response?.data?['message'] ?? 'Error de conexión',
//             statusCode: e.response?.statusCode,
//           );
//         }
//       }
//       throw ServerException(message: e.toString());
//     }
//   }

//   Future<void> requestPasswordReset({required String email}) async {
//     try {
//       final response = await _dio.post(
//         '/auth/forgot-password',
//         data: {'email': email},
//       );

//       if (response.statusCode! < 200 || response.statusCode! >= 300) {
//         throw ServerException(
//           message:
//               response.data['message'] ?? 'Error al solicitar recuperación',
//           statusCode: response.statusCode,
//         );
//       }
//     } catch (e) {
//       if (e is DioException) {
//         throw ServerException(
//           message: e.response?.data?['message'] ?? 'Error de conexión',
//           statusCode: e.response?.statusCode,
//         );
//       }
//       throw ServerException(message: e.toString());
//     }
//   }

//   Future<bool> resetPassword({
//     required String email,
//     required String code,
//     required String newPassword,
//   }) async {
//     try {
//       final response = await _dio.post(
//         '/auth/reset-password',
//         data: {
//           'email': email,
//           'code': code,
//           'new_password': newPassword,
//         },
//       );

//       if (response.statusCode! >= 200 && response.statusCode! < 300) {
//         return true;
//       }

//       throw ServerException(
//         message: response.data['message'] ?? 'Error al restablecer contraseña',
//         statusCode: response.statusCode,
//       );
//     } catch (e) {
//       if (e is DioException) {
//         throw ServerException(
//           message: e.response?.data?['message'] ?? 'Error de conexión',
//           statusCode: e.response?.statusCode,
//         );
//       }
//       throw ServerException(message: e.toString());
//     }
//   }
// }

//========================================

// import 'package:dio/dio.dart';
// import 'package:login_signup/core/errors/exceptions.dart';
// import 'package:login_signup/features/auth/data/models/user_model.dart';
// import '../../../../shared/local_storage/local_storage.dart';

// class AuthRemoteDataSource {
//   final Dio _dio;
//   final LocalStorage _localStorage;

//   AuthRemoteDataSource({
//     required Dio dio,
//     required LocalStorage localStorage,
//   })  : _dio = dio,
//         _localStorage = localStorage;

//   Future<Map<String, dynamic>> login({
//     required String email,
//     required String password,
//   }) async {
//     try {
//       final response = await _dio.post(
//         '/auth/login',
//         data: {
//           'email': email,
//           'password': password,
//         },
//       );

//       if (response.statusCode == 200) {
//         return response.data;
//       }
//       // Si el status code no es 200 pero no lanzó una DioException,
//       // aún así queremos lanzar una ServerException con el mensaje del servidor.
//       throw ServerException(
//         message: response.data['message'] ?? 'Error desconocido en el servidor',
//         statusCode: response.statusCode,
//       );
//     } on DioException catch (e) {
//       // Manejar errores de Dio
//       if (e.response != null) {
//         // El servidor respondió con un error (ej. 401, 400, 500)
//         throw ServerException(
//           message: e.response?.data['message'] ??
//               'Error del servidor: ${e.response?.statusCode}',
//           statusCode: e.response?.statusCode,
//         );
//       } else {
//         // Error de conexión (sin respuesta del servidor)
//         throw ServerException(
//           message: 'Error de red. Verifique su conexión a internet.',
//           statusCode: null, // No hay status code en este caso
//         );
//       }
//     } catch (e) {
//       // Capturar cualquier otra excepción inesperada
//       throw ServerException(
//         message: 'Ha ocurrido un error inesperado: ${e.toString()}',
//         statusCode: null,
//       );
//     }
//   }

//   Future<void> signOut() async {
//     try {
//       await _localStorage.deleteToken();
//     } catch (e) {
//       throw Exception('Error al cerrar sesión: ${e.toString()}');
//     }
//   }

//   Future<UserModel> register({
//     required String name,
//     required String lastname,
//     required String email,
//     required String phone,
//     required String password,
//   }) async {
//     try {
//       final response = await _dio.post(
//         '/auth/register',
//         data: {
//           'name': name,
//           'lastname': lastname,
//           'email': email,
//           'phone': phone,
//           'password': password,
//         },
//       );

//       if (response.statusCode == 201) {
//         return UserModel.fromJson(response.data);
//       }

//       throw ServerException(
//         message: response.data['message'] ?? 'Error desconocido en el registro',
//         statusCode: response.statusCode,
//       );
//     } on DioException catch (e) {
//       if (e.response != null) {
//         throw ServerException(
//           message: e.response?.data['message'] ??
//               'Error del servidor: ${e.response?.statusCode}',
//           statusCode: e.response?.statusCode,
//         );
//       } else {
//         throw ServerException(
//           message: 'Error de red. Verifique su conexión a internet.',
//           statusCode: null,
//         );
//       }
//     } catch (e) {
//       throw ServerException(
//         message:
//             'Ha ocurrido un error inesperado al registrar: ${e.toString()}',
//         statusCode: null,
//       );
//     }
//   }

//   // NUEVO: Método para solicitar código de verificación
//   Future<void> requestVerificationCode({required String email}) async {
//     try {
//       final response = await _dio.post(
//         '/auth/request-verification-code', // Asegúrate de que esta sea la URL correcta de tu API
//         data: {'email': email},
//       );

//       if (response.statusCode! < 200 || response.statusCode! >= 300) {
//         throw ServerException(
//           message: response.data['message'] ??
//               'Error al solicitar código de verificación',
//           statusCode: response.statusCode,
//         );
//       }
//     } on DioException catch (e) {
//       if (e.response != null) {
//         throw ServerException(
//           message: e.response?.data?['message'] ??
//               'Error de conexión al solicitar código',
//           statusCode: e.response?.statusCode,
//         );
//       }
//       throw ServerException(message: e.toString());
//     }
//   }

//   // NUEVO: Método para verificar el email
//   Future<bool> verifyEmail(
//       {required String email, required String code}) async {
//     try {
//       final response = await _dio.post(
//         '/auth/verify-email', // Asegúrate de que esta sea la URL correcta de tu API
//         data: {
//           'email': email,
//           'code': code,
//         },
//       );

//       if (response.statusCode! >= 200 && response.statusCode! < 300) {
//         return true;
//       }

//       throw ServerException(
//         message: response.data['message'] ?? 'Error al verificar email',
//         statusCode: response.statusCode,
//       );
//     } on DioException catch (e) {
//       if (e.response != null) {
//         throw ServerException(
//           message: e.response?.data?['message'] ??
//               'Error de conexión al verificar email',
//           statusCode: e.response?.statusCode,
//         );
//       }
//       throw ServerException(message: e.toString());
//     }
//   }

//   Future<void> requestPasswordReset({required String email}) async {
//     try {
//       final response = await _dio.post(
//         '/auth/forgot-password',
//         data: {'email': email},
//       );

//       if (response.statusCode! < 200 || response.statusCode! >= 300) {
//         throw ServerException(
//           message:
//               response.data['message'] ?? 'Error al solicitar recuperación',
//           statusCode: response.statusCode,
//         );
//       }
//     } on DioException catch (e) {
//       if (e.response != null) {
//         throw ServerException(
//           message: e.response?.data?['message'] ?? 'Error de conexión',
//           statusCode: e.response?.statusCode,
//         );
//       }
//       throw ServerException(message: e.toString());
//     }
//   }

//   Future<bool> resetPassword({
//     required String email,
//     required String code,
//     required String newPassword,
//   }) async {
//     try {
//       final response = await _dio.post(
//         '/auth/reset-password',
//         data: {
//           'email': email,
//           'code': code,
//           'new_password': newPassword,
//         },
//       );

//       if (response.statusCode! >= 200 && response.statusCode! < 300) {
//         return true;
//       }

//       throw ServerException(
//         message: response.data['message'] ?? 'Error al restablecer contraseña',
//         statusCode: response.statusCode,
//       );
//     } on DioException catch (e) {
//       if (e.response != null) {
//         throw ServerException(
//           message: e.response?.data?['message'] ?? 'Error de conexión',
//           statusCode: e.response?.statusCode,
//         );
//       }
//       throw ServerException(message: e.toString());
//     }
//   }
// }

// =========================================

// import 'package:dio/dio.dart';
// import 'package:login_signup/core/errors/exceptions.dart';
// import 'package:login_signup/features/auth/data/models/user_model.dart';
// import '../../../../shared/local_storage/local_storage.dart';

// class AuthRemoteDataSource {
//   final Dio _dio;
//   final LocalStorage _localStorage;

//   AuthRemoteDataSource({
//     required Dio dio,
//     required LocalStorage localStorage,
//   })  : _dio = dio,
//         _localStorage = localStorage;

//   Future<Map<String, dynamic>> login({
//     required String email,
//     required String password,
//   }) async {
//     try {
//       final response = await _dio.post(
//         '/auth/login',
//         data: {
//           'email': email,
//           'password': password,
//         },
//       );

//       if (response.statusCode == 200) {
//         return response.data;
//       }
//       // Si el status code no es 200 pero no lanzó una DioException,
//       // aún así queremos lanzar una ServerException con el mensaje del servidor.
//       throw ServerException(
//         message: response.data['message'] ?? 'Error desconocido en el servidor',
//         statusCode: response.statusCode,
//       );
//     } on DioException catch (e) {
//       // Manejar errores de Dio
//       if (e.response != null) {
//         // El servidor respondió con un error (ej. 401, 400, 500)
//         throw ServerException(
//           // Solo toma el 'message' del cuerpo de la respuesta.
//           message: e.response?.data['message'] ??
//               'Error del servidor: ${e.response?.statusCode}',
//           statusCode: e.response?.statusCode,
//         );
//       } else {
//         // Error de conexión (sin respuesta del servidor)
//         throw ServerException(
//           message: 'Error de red. Verifique su conexión a internet.',
//           statusCode: null, // No hay status code en este caso
//         );
//       }
//     }
//     // Eliminado el catch (e) general aquí.
//     // Cualquier otra excepción inesperada se propagará a la capa del repositorio.
//   }

//   Future<void> signOut() async {
//     try {
//       await _localStorage.deleteToken();
//     } catch (e) {
//       // Este catch es para errores de localStorage, no de red/servidor
//       throw Exception('Error al cerrar sesión: ${e.toString()}');
//     }
//   }

//   Future<UserModel> register({
//     required String name,
//     required String lastname,
//     required String email,
//     required String phone,
//     required String password,
//   }) async {
//     try {
//       final response = await _dio.post(
//         '/auth/register',
//         data: {
//           'name': name,
//           'lastname': lastname,
//           'email': email,
//           'phone': phone,
//           'password': password,
//         },
//       );

//       if (response.statusCode == 201) {
//         return UserModel.fromJson(response.data);
//       }

//       throw ServerException(
//         message: response.data['message'] ?? 'Error desconocido en el registro',
//         statusCode: response.statusCode,
//       );
//     } on DioException catch (e) {
//       if (e.response != null) {
//         throw ServerException(
//           message: e.response?.data['message'] ??
//               'Error del servidor: ${e.response?.statusCode}',
//           statusCode: e.response?.statusCode,
//         );
//       } else {
//         throw ServerException(
//           message: 'Error de red. Verifique su conexión a internet.',
//           statusCode: null,
//         );
//       }
//     }
//     // Eliminado el catch (e) general aquí.
//   }

//   // Método para solicitar código de verificación
//   Future<void> requestVerificationCode({required String email}) async {
//     try {
//       final response = await _dio.post(
//         '/auth/request-verification-code', // Asegúrate de que esta sea la URL correcta de tu API
//         data: {'email': email},
//       );

//       if (response.statusCode! < 200 || response.statusCode! >= 300) {
//         throw ServerException(
//           message: response.data['message'] ??
//               'Error al solicitar código de verificación',
//           statusCode: response.statusCode,
//         );
//       }
//     } on DioException catch (e) {
//       if (e.response != null) {
//         throw ServerException(
//           message: e.response?.data?['message'] ??
//               'Error de conexión al solicitar código',
//           statusCode: e.response?.statusCode,
//         );
//       }
//       throw ServerException(message: e.toString());
//     }
//     // Eliminado el catch (e) general aquí.
//   }

//   // Método para verificar el email
//   Future<bool> verifyEmail(
//       {required String email, required String code}) async {
//     try {
//       final response = await _dio.post(
//         '/auth/verify-email', // Asegúrate de que esta sea la URL correcta de tu API
//         data: {
//           'email': email,
//           'code': code,
//         },
//       );

//       if (response.statusCode! >= 200 && response.statusCode! < 300) {
//         return true;
//       }

//       throw ServerException(
//         message: response.data['message'] ?? 'Error al verificar email',
//         statusCode: response.statusCode,
//       );
//     } on DioException catch (e) {
//       if (e.response != null) {
//         throw ServerException(
//           message: e.response?.data?['message'] ??
//               'Error de conexión al verificar email',
//           statusCode: e.response?.statusCode,
//         );
//       }
//       throw ServerException(message: e.toString());
//     }
//     // Eliminado el catch (e) general aquí.
//   }

//   Future<void> requestPasswordReset({required String email}) async {
//     try {
//       final response = await _dio.post(
//         '/auth/forgot-password',
//         data: {'email': email},
//       );

//       if (response.statusCode! < 200 || response.statusCode! >= 300) {
//         throw ServerException(
//           message:
//               response.data['message'] ?? 'Error al solicitar recuperación',
//           statusCode: response.statusCode,
//         );
//       }
//     } on DioException catch (e) {
//       if (e.response != null) {
//         throw ServerException(
//           message: e.response?.data?['message'] ?? 'Error de conexión',
//           statusCode: e.response?.statusCode,
//         );
//       }
//       throw ServerException(message: e.toString());
//     }
//     // Eliminado el catch (e) general aquí.
//   }

//   Future<bool> resetPassword({
//     required String email,
//     required String code,
//     required String newPassword,
//   }) async {
//     try {
//       final response = await _dio.post(
//         '/auth/reset-password',
//         data: {
//           'email': email,
//           'code': code,
//           'new_password': newPassword,
//         },
//       );

//       if (response.statusCode! >= 200 && response.statusCode! < 300) {
//         return true;
//       }

//       throw ServerException(
//         message: response.data['message'] ?? 'Error al restablecer contraseña',
//         statusCode: response.statusCode,
//       );
//     } on DioException catch (e) {
//       if (e.response != null) {
//         throw ServerException(
//           message: e.response?.data?['message'] ?? 'Error de conexión',
//           statusCode: e.response?.statusCode,
//         );
//       }
//       throw ServerException(message: e.toString());
//     }
//     // Eliminado el catch (e) general aquí.
//   }
// }

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
      if (e.response != null) {
        // El servidor respondió con un error (ej. 401, 400, 500)
        throw ServerException(
          message: e.response?.data['message'] ??
              'Error del servidor: ${e.response?.statusCode}',
          statusCode: e.response?.statusCode,
        );
      } else {
        // Error de conexión (sin respuesta del servidor)
        // Verificar si es un "Connection refused" de forma más robusta
        if (e.type == DioExceptionType.connectionError &&
            e.error is SocketException) {
          final socketException = e.error as SocketException;
          // Códigos de error comunes para "Connection refused"
          if (socketException.osError != null &&
              (socketException.osError!.errorCode == 111 || // Linux/Android
                  socketException.osError!.errorCode == 61 || // macOS/iOS
                  socketException.osError!.errorCode == 10061 // Windows
              )) {
            throw ServerException(
              message:
                  'Error interno del servidor. Por favor, inténtelo de nuevo más tarde.',
              statusCode: null,
            );
          }
        }
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
        '/auth/register',
        data: {
          'name': name,
          'lastname': lastname,
          'email': email,
          'phone': phone,
          'password': password,
        },
      );

      if (response.statusCode == 201) {
        return UserModel.fromJson(response.data);
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
        if (e.type == DioExceptionType.connectionError &&
            e.error is SocketException) {
          final socketException = e.error as SocketException;
          if (socketException.osError != null &&
              (socketException.osError!.errorCode == 111 ||
                  socketException.osError!.errorCode == 61 ||
                  socketException.osError!.errorCode == 10061)) {
            throw ServerException(
              message:
                  'Error interno del servidor. Por favor, inténtelo de nuevo más tarde.',
              statusCode: null,
            );
          }
        }
        throw ServerException(
          message: 'Error de red. Verifique su conexión a internet.',
          statusCode: null,
        );
      }
    }
  }

  // Método para solicitar código de verificación
  Future<void> requestVerificationCode({required String email}) async {
    try {
      final response = await _dio.post(
        '/auth/request-verification-code',
        data: {'email': email},
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
        if (e.type == DioExceptionType.connectionError &&
            e.error is SocketException) {
          final socketException = e.error as SocketException;
          if (socketException.osError != null &&
              (socketException.osError!.errorCode == 111 ||
                  socketException.osError!.errorCode == 61 ||
                  socketException.osError!.errorCode == 10061)) {
            throw ServerException(
              message:
                  'Error interno del servidor. Por favor, inténtelo de nuevo más tarde.',
              statusCode: null,
            );
          }
        }
        throw ServerException(
            message: 'Error de red. Verifique su conexión a internet.');
      }
    }
  }

  // Método para verificar el email
  Future<bool> verifyEmail(
      {required String email, required String code}) async {
    try {
      final response = await _dio.post(
        '/auth/verify-email',
        data: {
          'email': email,
          'code': code,
        },
      );

      if (response.statusCode! >= 200 && response.statusCode! < 300) {
        return true;
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
        if (e.type == DioExceptionType.connectionError &&
            e.error is SocketException) {
          final socketException = e.error as SocketException;
          if (socketException.osError != null &&
              (socketException.osError!.errorCode == 111 ||
                  socketException.osError!.errorCode == 61 ||
                  socketException.osError!.errorCode == 10061)) {
            throw ServerException(
              message:
                  'Error interno del servidor. Por favor, inténtelo de nuevo más tarde.',
              statusCode: null,
            );
          }
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
        if (e.type == DioExceptionType.connectionError &&
            e.error is SocketException) {
          final socketException = e.error as SocketException;
          if (socketException.osError != null &&
              (socketException.osError!.errorCode == 111 ||
                  socketException.osError!.errorCode == 61 ||
                  socketException.osError!.errorCode == 10061)) {
            throw ServerException(
              message:
                  'Error interno del servidor. Por favor, inténtelo de nuevo más tarde.',
              statusCode: null,
            );
          }
        }
        throw ServerException(
            message: 'Error de red. Verifique su conexión a internet.');
      }
    }
  }

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
          'new_password': newPassword,
        },
      );

      if (response.statusCode! >= 200 && response.statusCode! < 300) {
        return true;
      }

      throw ServerException(
        message: response.data['message'] ?? 'Error al restablecer contraseña',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      if (e.response != null) {
        throw ServerException(
          message: e.response?.data?['message'] ?? 'Error de conexión',
          statusCode: e.response?.statusCode,
        );
      } else {
        if (e.type == DioExceptionType.connectionError &&
            e.error is SocketException) {
          final socketException = e.error as SocketException;
          if (socketException.osError != null &&
              (socketException.osError!.errorCode == 111 ||
                  socketException.osError!.errorCode == 61 ||
                  socketException.osError!.errorCode == 10061)) {
            throw ServerException(
              message:
                  'Error interno del servidor. Por favor, inténtelo de nuevo más tarde.',
              statusCode: null,
            );
          }
        }
        throw ServerException(
            message: 'Error de red. Verifique su conexión a internet.');
      }
    }
  }
}
