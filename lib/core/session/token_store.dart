import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Único dueño del token de sesión (ARQUITECTURA.md §2.2).
///
/// Lo usan el `AuthInterceptor`, el `SessionRepository` y, mientras duren las
/// features sin migrar, `LocalStorage` (que delega aquí sus métodos de token).
abstract interface class TokenStore {
  /// Token JWT actual, o `null` si no hay sesión.
  Future<String?> readToken();

  /// Un token vacío equivale a `clearToken()`.
  Future<void> saveToken(String token);

  /// Borra solo el token (no el resto de preferencias).
  Future<void> clearToken();
}

/// `TokenStore` sobre `flutter_secure_storage`.
///
/// Usa la misma entrada que la app ya escribía con `LocalStorage` (`token`):
/// tras actualizar, la sesión guardada se sigue leyendo sin mover datos y los
/// lectores antiguos que leen `token` directamente (Fase 4) no se rompen.
/// Un valor vacío o solo con espacios cuenta como "sin sesión" y se borra.
class SecureTokenStore implements TokenStore {
  static const tokenKey = 'token';

  final FlutterSecureStorage _storage;

  const SecureTokenStore(this._storage);

  @override
  Future<String?> readToken() async {
    final token = await _storage.read(key: tokenKey);
    if (token == null) return null;
    if (token.trim().isEmpty) {
      await _storage.delete(key: tokenKey);
      return null;
    }
    return token;
  }

  @override
  Future<void> saveToken(String token) {
    final value = token.trim();
    if (value.isEmpty) return clearToken();
    return _storage.write(key: tokenKey, value: value);
  }

  @override
  Future<void> clearToken() => _storage.delete(key: tokenKey);
}
