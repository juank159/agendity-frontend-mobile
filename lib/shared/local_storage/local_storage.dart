// lib/shared/local_storage/local_storage.dart

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:login_signup/core/session/token_store.dart';
import 'package:login_signup/core/utils/app_logger.dart';

class LocalStorage {
  final FlutterSecureStorage _storage;

  /// El token lo guarda solo `TokenStore` (3.02); estos métodos delegan en él
  /// mientras queden features sin migrar.
  final TokenStore _tokens;

  LocalStorage(this._storage, {TokenStore? tokenStore})
      : _tokens = tokenStore ?? SecureTokenStore(_storage);

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

      AppLogger.debug('LocalStorage initialized successfully');
    } catch (e) {
      AppLogger.error('Error initializing LocalStorage', e);
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

      AppLogger.debug('Storage operations verified successfully');
    } catch (e) {
      throw Exception('Failed to verify storage operations: $e');
    }
  }

  Future<String?> getToken() => _tokens.readToken();

  Future<void> deleteToken() => _tokens.clearToken();

  Future<void> clearAllData() async {
    await _storage.deleteAll();
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
