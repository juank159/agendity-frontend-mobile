import 'package:dio/dio.dart';
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
}
