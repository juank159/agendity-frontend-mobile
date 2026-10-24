import 'package:login_signup/shared/local_storage/local_storage.dart';

/// Acceso al token de sesión (ARQUITECTURA.md §2.2).
///
/// 3.01 solo necesita leerlo (lo usa el `AuthInterceptor`). La 3.02 completa
/// esta interfaz (guardar y borrar) y sustituye la implementación.
abstract interface class TokenStore {
  /// Token JWT actual, o `null` si no hay sesión.
  Future<String?> readToken();
}

/// Implementación temporal: lee el token que ya guarda `LocalStorage`
/// (clave `token`). La retira la 3.02.
class LocalStorageTokenStore implements TokenStore {
  final LocalStorage _storage;

  const LocalStorageTokenStore(this._storage);

  @override
  Future<String?> readToken() => _storage.getToken();
}
