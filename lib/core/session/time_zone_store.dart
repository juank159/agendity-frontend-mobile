import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Última zona horaria del negocio conocida (D-15). Sirve para el auto-login
/// sin red: las horas se siguen mostrando en la zona del negocio y no en la
/// por defecto. La escribe y la borra solo `SessionService`.
abstract interface class TimeZoneStore {
  Future<String?> read();
  Future<void> save(String timeZone);
  Future<void> clear();
}

/// `TimeZoneStore` sobre `flutter_secure_storage` (el logout lo borra también
/// con `LocalStorage.clearAllData`).
class SecureTimeZoneStore implements TimeZoneStore {
  static const timeZoneKey = 'business_timezone';

  final FlutterSecureStorage _storage;

  const SecureTimeZoneStore(this._storage);

  @override
  Future<String?> read() => _storage.read(key: timeZoneKey);

  @override
  Future<void> save(String timeZone) =>
      _storage.write(key: timeZoneKey, value: timeZone);

  @override
  Future<void> clear() => _storage.delete(key: timeZoneKey);
}
