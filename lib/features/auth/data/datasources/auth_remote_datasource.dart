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
}
