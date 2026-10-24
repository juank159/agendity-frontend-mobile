import 'package:flutter_test/flutter_test.dart';
import 'package:login_signup/core/session/session_repository.dart';
import 'package:login_signup/core/session/session_service.dart';

import 'jwt_helper.dart';
import 'memory_token_store.dart';

void main() {
  final now = DateTime.utc(2026, 10, 23, 12);
  late MemoryTokenStore store;
  late SessionService service;
  late int expiredCalls;

  String token(String id, {Duration expiresIn = const Duration(hours: 1)}) =>
      fakeJwt({
        'id': id,
        'roles': ['Owner'],
        'exp': epochSeconds(now.add(expiresIn))
      });

  setUp(() {
    store = MemoryTokenStore();
    expiredCalls = 0;
    service = SessionService(
      tokenStore: store,
      repository: SessionRepository(store, clock: () => now),
    )..onSessionExpired = () => expiredCalls++;
  });

  test('start guarda el token y devuelve la sesión', () async {
    final session = await service.start(token('u1'));
    expect(session.userId, 'u1');
    expect((await service.current())!.userId, 'u1');
  });

  test('start con token malformado lanza y no guarda', () async {
    await expectLater(service.start('basura'), throwsFormatException);
    expect(store.token, isNull);
  });

  test('restore: vigente → sesión; vencido o malformado → null y lo borra',
      () async {
    store.token = token('u1');
    expect((await service.restore())!.userId, 'u1');

    store.token = token('u1', expiresIn: const Duration(hours: -1));
    expect(await service.restore(), isNull);
    expect(store.token, isNull);

    store.token = 'a.b';
    expect(await service.restore(), isNull);
    expect(store.token, isNull);
  });

  test('end borra el token', () async {
    store.token = token('u1');
    await service.end();
    expect(await service.current(), isNull);
  });

  test('handleSessionExpired con el token actual: borra y avisa', () async {
    final current = token('u1');
    store.token = current;
    await service.handleSessionExpired(current);
    expect(store.token, isNull);
    expect(expiredCalls, 1);
  });

  test('handleSessionExpired con un token viejo (ya hubo otro login): nada',
      () async {
    final viejo = token('u1');
    final nuevo = token('u2');
    store.token = nuevo;
    await service.handleSessionExpired(viejo);
    expect(store.token, nuevo);
    expect(expiredCalls, 0);
  });
}
