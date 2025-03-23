// lib/shared/local_storage/local_storage.dart

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

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
    // Primero intentar obtener el ID almacenado directamente
    final storedId = await _storage.read(key: 'userId');

    // Si existe el ID almacenado, devolverlo
    if (storedId != null && storedId.isNotEmpty) {
      return storedId;
    }

    // Si no hay ID almacenado, intentar extraerlo del token JWT
    try {
      final token = await getToken();
      if (token != null && token.isNotEmpty) {
        // Decodificar el token JWT (el payload está en la segunda parte)
        final parts = token.split('.');
        if (parts.length >= 2) {
          final payload = parts[1];
          // Normalizar y decodificar Base64
          final normalized = base64Url.normalize(payload);
          final decoded = utf8.decode(base64Url.decode(normalized));
          final Map<String, dynamic> data = json.decode(decoded);

          // El ID del usuario está en el campo 'id' del token
          if (data.containsKey('id')) {
            // Guardar el ID para futuras consultas
            final userId = data['id'];
            await _storage.write(key: 'userId', value: userId);
            print('ID de usuario extraído del token y guardado: $userId');
            return userId;
          }
        }
      }
      print(
          'No se pudo extraer ID del token: token inválido o estructura inesperada');
      return null;
    } catch (e) {
      print('Error al extraer ID del token: $e');
      return null;
    }
  }

  Future<void> saveToken(String token) async {
    await _storage.write(key: 'token', value: token);
    print('Token guardado: $token');

    // Extraer y guardar el ID del usuario del token JWT
    try {
      final parts = token.split('.');
      if (parts.length >= 2) {
        final payload = parts[1];
        final normalized = base64Url.normalize(payload);
        final decoded = utf8.decode(base64Url.decode(normalized));
        final Map<String, dynamic> data = json.decode(decoded);
        if (data.containsKey('id')) {
          await _storage.write(key: 'userId', value: data['id']);
          print('ID de usuario guardado automáticamente: ${data['id']}');
        }
      }
    } catch (e) {
      print('Error al extraer y guardar ID del token: $e');
    }
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
