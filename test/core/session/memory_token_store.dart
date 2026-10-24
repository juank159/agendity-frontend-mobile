import 'package:login_signup/core/session/token_store.dart';

/// `TokenStore` en memoria para tests.
class MemoryTokenStore implements TokenStore {
  MemoryTokenStore([this.token]);
  String? token;

  @override
  Future<String?> readToken() async => token;

  @override
  Future<void> saveToken(String value) async => token = value;

  @override
  Future<void> clearToken() async => token = null;
}
