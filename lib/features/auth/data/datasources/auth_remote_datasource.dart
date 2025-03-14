import 'package:dio/dio.dart';
import 'package:login_signup/core/errors/exceptions.dart';
import 'package:login_signup/features/auth/data/models/user_model.dart';
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

      throw Exception('Error en inicio de sesión');
    } catch (e) {
      throw Exception('Error en inicio de sesión: ${e.toString()}');
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
        '/auth/register/owner',
        data: {
          'name': name,
          'lastname': lastname,
          'email': email,
          'phone': phone,
          'password': password,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Guardar token
        final token = response.data['token'];
        if (token != null) {
          await _localStorage.saveToken(token);
        }

        // Asegurar la estructura correcta para fromJson
        // Tu UserModel.fromJson espera que los datos estén dentro de una clave 'user'
        final userData = {
          'user':
              response.data['user'] // Aseguramos que sea la estructura correcta
        };

        // Convertir y devolver el modelo de usuario
        return UserModel.fromJson(userData);
      } else {
        throw ServerException(
          message: response.data['message'] ?? 'Error al registrar usuario',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data?['message'] ?? 'Error de conexión',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  Future<void> requestVerificationCode({required String email}) async {
    try {
      final response = await _dio.post(
        '/auth/verify/request-code',
        data: {'email': email},
      );

      if (response.statusCode! < 200 || response.statusCode! >= 300) {
        throw ServerException(
          message: response.data['message'] ?? 'Error al solicitar código',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is DioException) {
        throw ServerException(
          message: e.response?.data?['message'] ?? 'Error de conexión',
          statusCode: e.response?.statusCode,
        );
      }
      throw ServerException(message: e.toString());
    }
  }

  Future<bool> verifyEmail(
      {required String email, required String code}) async {
    try {
      final response = await _dio.post(
        '/auth/verify/email',
        data: {
          'email': email,
          'code': code,
        },
      );

      // Considera cualquier código 2xx como éxito
      if (response.statusCode! >= 200 && response.statusCode! < 300) {
        return response.data['is_verified'] ?? false;
      }

      throw ServerException(
        message: response.data['message'] ?? 'Error de verificación',
        statusCode: response.statusCode,
      );
    } catch (e) {
      if (e is DioException) {
        // Solo manejar errores reales (4xx, 5xx)
        if (e.response?.statusCode != null && e.response!.statusCode! >= 400) {
          throw ServerException(
            message: e.response?.data?['message'] ?? 'Error de conexión',
            statusCode: e.response?.statusCode,
          );
        }
      }
      throw ServerException(message: e.toString());
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
    } catch (e) {
      if (e is DioException) {
        throw ServerException(
          message: e.response?.data?['message'] ?? 'Error de conexión',
          statusCode: e.response?.statusCode,
        );
      }
      throw ServerException(message: e.toString());
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
    } catch (e) {
      if (e is DioException) {
        throw ServerException(
          message: e.response?.data?['message'] ?? 'Error de conexión',
          statusCode: e.response?.statusCode,
        );
      }
      throw ServerException(message: e.toString());
    }
  }
}
