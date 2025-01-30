// lib/shared/local_storage/local_storage.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LocalStorage {
  final FlutterSecureStorage _storage;

  LocalStorage(this._storage);

  Future<void> saveToken(String token) async {
    await _storage.write(key: 'token', value: token);
    print('Token guardado: $token'); // Debug
  }

  Future<String?> getToken() async {
    final token = await _storage.read(key: 'token');
    print('Token actual: $token'); // Debug
    return token;
  }

  Future<void> deleteToken() async {
    print('Intentando eliminar token...'); // Debug
    final tokenAntes = await getToken();
    print('Token antes de eliminar: $tokenAntes'); // Debug

    await _storage.delete(key: 'token');

    final tokenDespues = await getToken();
    print('Token después de eliminar: $tokenDespues'); // Debug
  }

  Future<void> clearAllData() async {
    print('Limpiando todos los datos almacenados...'); // Debug
    await _storage.deleteAll();
    final allData = await _storage.readAll();
    print('Datos restantes después de limpiar: $allData'); // Debug
  }

  // Métodos adicionales para otros datos si los necesitas
  Future<void> saveUserData(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  Future<String?> getUserData(String key) async {
    return await _storage.read(key: key);
  }

  Future<void> deleteUserData(String key) async {
    await _storage.delete(key: key);
  }
}
