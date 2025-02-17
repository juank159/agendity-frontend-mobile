// // lib/shared/local_storage/local_storage.dart
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// class LocalStorage {
//   final FlutterSecureStorage _storage;

//   LocalStorage(this._storage);

//   Future<void> saveUserInfo(Map<String, dynamic> userData) async {
//     await _storage.write(key: 'userId', value: userData['id']);
//     await _storage.write(key: 'userName', value: userData['name']);
//     await _storage.write(key: 'userEmail', value: userData['email']);
//   }

//   Future<String?> getUserId() async {
//     return await _storage.read(key: 'userId');
//   }

//   Future<void> saveToken(String token) async {
//     await _storage.write(key: 'token', value: token);
//     print('Token guardado: $token'); // Debug
//   }

//   Future<String?> getToken() async {
//     final token = await _storage.read(key: 'token');
//     print('Token actual: $token'); // Debug
//     return token;
//   }

//   Future<void> deleteToken() async {
//     print('Intentando eliminar token...'); // Debug
//     final tokenAntes = await getToken();
//     print('Token antes de eliminar: $tokenAntes'); // Debug

//     await _storage.delete(key: 'token');

//     final tokenDespues = await getToken();
//     print('Token después de eliminar: $tokenDespues'); // Debug
//   }

//   Future<void> clearAllData() async {
//     print('Limpiando todos los datos almacenados...'); // Debug
//     await _storage.deleteAll();
//     final allData = await _storage.readAll();
//     print('Datos restantes después de limpiar: $allData'); // Debug
//   }

//   // Métodos adicionales para otros datos si los necesitas
//   Future<void> saveUserData(String key, String value) async {
//     await _storage.write(key: key, value: value);
//   }

//   Future<String?> getUserData(String key) async {
//     return await _storage.read(key: key);
//   }

//   Future<void> deleteUserData(String key) async {
//     await _storage.delete(key: key);
//   }
// }

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LocalStorage {
  final FlutterSecureStorage _storage;

  LocalStorage(this._storage);

  Future<void> init() async {
    try {
      // Verificar que el almacenamiento esté accesible
      await _storage.read(key: 'test');

      // Verificar y limpiar datos inválidos si es necesario
      final token = await getToken();
      if (token?.isEmpty ?? true) {
        await deleteToken();
      }

      // Verificar que todos los métodos de almacenamiento estén funcionando
      await _testStorageOperations();

      print('LocalStorage initialized successfully');
    } catch (e) {
      print('Error initializing LocalStorage: $e');
      rethrow;
    }
  }

  Future<void> _testStorageOperations() async {
    try {
      // Test write
      await _storage.write(key: '_test_key', value: 'test_value');

      // Test read
      final testValue = await _storage.read(key: '_test_key');
      if (testValue != 'test_value') {
        throw Exception('Storage read/write verification failed');
      }

      // Test delete
      await _storage.delete(key: '_test_key');

      print('Storage operations verified successfully');
    } catch (e) {
      throw Exception('Failed to verify storage operations: $e');
    }
  }

  Future<void> saveUserInfo(Map<String, dynamic> userData) async {
    await _storage.write(key: 'userId', value: userData['id']);
    await _storage.write(key: 'userName', value: userData['name']);
    await _storage.write(key: 'userEmail', value: userData['email']);
  }

  Future<String?> getUserId() async {
    return await _storage.read(key: 'userId');
  }

  Future<void> saveToken(String token) async {
    await _storage.write(key: 'token', value: token);
    print('Token guardado: $token');
  }

  Future<String?> getToken() async {
    final token = await _storage.read(key: 'token');
    print('Token actual: $token');
    return token;
  }

  Future<void> deleteToken() async {
    print('Intentando eliminar token...');
    final tokenAntes = await getToken();
    print('Token antes de eliminar: $tokenAntes');

    await _storage.delete(key: 'token');

    final tokenDespues = await getToken();
    print('Token después de eliminar: $tokenDespues');
  }

  Future<void> clearAllData() async {
    print('Limpiando todos los datos almacenados...');
    await _storage.deleteAll();
    final allData = await _storage.readAll();
    print('Datos restantes después de limpiar: $allData');
  }

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
