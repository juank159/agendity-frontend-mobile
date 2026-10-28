import 'package:login_signup/core/session/time_zone_store.dart';
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

/// `TimeZoneStore` en memoria para tests.
class MemoryTimeZoneStore implements TimeZoneStore {
  MemoryTimeZoneStore([this.timeZone]);
  String? timeZone;

  @override
  Future<String?> read() async => timeZone;

  @override
  Future<void> save(String value) async => timeZone = value;

  @override
  Future<void> clear() async => timeZone = null;
}
