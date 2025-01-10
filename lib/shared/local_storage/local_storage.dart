import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LocalStorage {
  final FlutterSecureStorage _storage;

  LocalStorage(this._storage);

  // Token management
  Future<void> saveToken(String token) async {
    await _storage.write(key: 'auth_token', value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: 'auth_token');
  }

  // User data management
  Future<void> saveUserData(String email, String name) async {
    await _storage.write(key: 'user_email', value: email);
    await _storage.write(key: 'user_name', value: name);
  }

  Future<Map<String, String?>> getUserData() async {
    return {
      'email': await _storage.read(key: 'user_email'),
      'name': await _storage.read(key: 'user_name'),
    };
  }

  // Session management
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }

  Future<void> clearSession() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      throw Exception('Error al cerrar sesión: $e');
    }
  }

  // Para limpiar datos específicos si es necesario
  Future<void> clearUserData() async {
    await _storage.delete(key: 'user_email');
    await _storage.delete(key: 'user_name');
  }
}
