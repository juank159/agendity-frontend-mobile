import 'package:flutter_test/flutter_test.dart';
import 'package:login_signup/core/session/session_repository.dart';

import 'jwt_helper.dart';
import 'memory_token_store.dart';

void main() {
  final now = DateTime.utc(2026, 10, 23, 12);
  final exp = now.add(const Duration(hours: 20));

  SessionRepository repo(MemoryTokenStore store) =>
      SessionRepository(store, clock: () => now);

  test('token nuevo (2.01): id, roles, tenantId, ownerId y exp', () async {
    final token = fakeJwt({
      'id': 'emp-1',
      'name': 'Ana',
      'email': 'ana@x.co',
      'roles': ['Employee'],
      'tenantId': 'owner-1',
      'ownerId': 'owner-1',
      'tenant_id': 'owner-1',
      'iat': epochSeconds(now),
      'exp': epochSeconds(exp),
    });
    final session = await repo(MemoryTokenStore(token)).activeSession();

    expect(session, isNotNull);
    expect(session!.userId, 'emp-1');
    expect(session.name, 'Ana');
    expect(session.email, 'ana@x.co');
    expect(session.roles, ['Employee']);
    expect(session.tenantId, 'owner-1');
    expect(session.ownerId, 'owner-1');
    expect(session.expiresAt, exp);
    expect(session.isOnlyEmployee, true);
    expect(session.isOwner, false);
    expect(session.token, token);
  });

  test('token antiguo sin tenantId/ownerId: desconocidos, sin romper',
      () async {
    final token = fakeJwt({
      'id': 'owner-1',
      'email': 'o@x.co',
      'roles': ['Owner'],
      'tenant_id': 'valor-antiguo-no-fiable',
      'exp': epochSeconds(exp),
    });
    final session = await repo(MemoryTokenStore(token)).activeSession();

    expect(session!.userId, 'owner-1');
    expect(session.tenantId, isNull);
    expect(session.ownerId, isNull);
    expect(session.isOwner, true);
  });

  test('token sin exp: no se da por vencido', () async {
    final session =
        await repo(MemoryTokenStore(fakeJwt({'id': 'u'}))).activeSession();
    expect(session!.expiresAt, isNull);
    expect(session.roles, isEmpty);
  });

  test('roles en formatos viejos (texto o lista de {name})', () {
    expect(
        SessionRepository.decode(fakeJwt({'id': 'u', 'roles': 'Owner'}))!.roles,
        ['Owner']);
    expect(
        SessionRepository.decode(fakeJwt({
          'id': 'u',
          'roles': [
            {'name': 'Owner'},
            {'name': 'Employee'}
          ]
        }))!
            .roles,
        ['Owner', 'Employee']);
  });

  test('token vencido: readSession lo devuelve marcado, activeSession null',
      () async {
    final store = MemoryTokenStore(fakeJwt({
      'id': 'u',
      'exp': epochSeconds(now.subtract(const Duration(minutes: 1))),
    }));
    final repository = repo(store);

    final read = await repository.readSession();
    expect(read, isNotNull);
    expect(read!.isExpiredAt(now), true);
    expect(await repository.activeSession(), isNull);
  });

  test('vence justo en exp', () {
    final session = SessionRepository.decode(
        fakeJwt({'id': 'u', 'exp': epochSeconds(now)}))!;
    expect(session.isExpiredAt(now), true);
    expect(
        session.isExpiredAt(now.subtract(const Duration(seconds: 1))), false);
  });

  group('token malformado → null', () {
    final cases = <String, String>{
      'vacío': '',
      'sin puntos': 'abc',
      'dos partes': 'a.b',
      'payload no base64': 'a.%%%.c',
      'payload no JSON': 'a.${'bm9qc29u'}.c', // "nojson"
      'payload JSON no objeto': 'a.WzFd.c', // [1]
      'sin id': fakeJwt({
        'roles': ['Owner']
      }),
    };
    cases.forEach((name, token) {
      test(name, () async {
        expect(SessionRepository.decode(token), isNull);
        expect(await repo(MemoryTokenStore(token)).readSession(), isNull);
      });
    });
  });

  test('sin token → null', () async {
    expect(await repo(MemoryTokenStore()).activeSession(), isNull);
  });

  test('decodifica una sola vez por token y se entera de un token nuevo',
      () async {
    final store = MemoryTokenStore(fakeJwt({'id': 'a'}));
    final repository = repo(store);

    final first = await repository.readSession();
    final second = await repository.readSession();
    expect(identical(first, second), true);

    store.token = fakeJwt({'id': 'b'});
    expect((await repository.readSession())!.userId, 'b');

    store.token = null;
    expect(await repository.readSession(), isNull);
  });
}
