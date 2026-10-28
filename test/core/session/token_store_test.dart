import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:login_signup/core/session/token_store.dart';
import 'package:login_signup/shared/local_storage/local_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const storage = FlutterSecureStorage();
  const store = SecureTokenStore(storage);

  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('sin token → null', () async {
    expect(await store.readToken(), isNull);
  });

  test('guardar, leer y borrar', () async {
    await store.saveToken('abc.def.ghi');
    expect(await store.readToken(), 'abc.def.ghi');
    await store.clearToken();
    expect(await store.readToken(), isNull);
  });

  test('migración: el token que guardaba LocalStorage se sigue leyendo',
      () async {
    // Estado de un teléfono con la versión anterior instalada.
    FlutterSecureStorage.setMockInitialValues(
        {'token': 'token.viejo.x', 'userId': 'u1', 'theme': 'dark'});
    expect(await store.readToken(), 'token.viejo.x');
  });

  test('borrar el token no toca el resto de datos', () async {
    FlutterSecureStorage.setMockInitialValues(
        {'token': 'a.b.c', 'userId': 'u1'});
    await store.clearToken();
    expect(await storage.read(key: 'userId'), 'u1');
  });

  test('token vacío guardado cuenta como sin sesión y se borra', () async {
    FlutterSecureStorage.setMockInitialValues({'token': '  '});
    expect(await store.readToken(), isNull);
    expect(await storage.containsKey(key: 'token'), false);
  });

  test('guardar un token vacío equivale a borrarlo; se guarda sin espacios',
      () async {
    await store.saveToken('  a.b.c \n');
    expect(await store.readToken(), 'a.b.c');
    await store.saveToken('');
    expect(await store.readToken(), isNull);
  });

  test('LocalStorage delega el token en TokenStore (una sola entrada)',
      () async {
    final local = LocalStorage(storage, tokenStore: store);
    await store.saveToken('n.u.evo');
    expect(await local.getToken(), 'n.u.evo');
    await local.deleteToken();
    expect(await store.readToken(), isNull);
  });
}
