import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/session/session_repository.dart';
import 'package:login_signup/core/session/session_service.dart';
import 'package:login_signup/shared/controller/session_controller.dart';

import '../../core/session/jwt_helper.dart';
import '../../core/session/memory_token_store.dart';

void main() {
  final now = DateTime.utc(2026, 10, 23, 12);
  late MemoryTokenStore store;
  late SessionController controller;

  String token(String id,
          {List<String> roles = const ['Owner'],
          Duration expiresIn = const Duration(hours: 1)}) =>
      fakeJwt({
        'id': id,
        'name': 'Ana',
        'email': 'ana@test.co',
        'roles': roles,
        'tenantId': 't1',
        'exp': epochSeconds(now.add(expiresIn)),
      });

  setUp(() {
    Get.testMode = true;
    store = MemoryTokenStore();
    controller = SessionController(
      SessionService(
        tokenStore: store,
        repository: SessionRepository(store, clock: () => now),
      ),
      clock: () => now,
    );
  });

  test('sin sesión: no está logueado y no es Owner', () {
    expect(controller.isLoggedIn, isFalse);
    expect(controller.isOwner, isFalse);
    expect(controller.userId, '');
  });

  test('restore carga una sesión guardada y vigente', () async {
    store.token = token('u1');
    final session = await controller.restore();
    expect(session?.userId, 'u1');
    expect(controller.isLoggedIn, isTrue);
    expect(controller.isOwner, isTrue);
    expect(controller.tenantId, 't1');
    expect(controller.name, 'Ana');
  });

  test('restore con token vencido no entra y lo borra', () async {
    store.token = token('u1', expiresIn: const Duration(minutes: -1));
    expect(await controller.restore(), isNull);
    expect(controller.isLoggedIn, isFalse);
    expect(store.token, isNull);
  });

  test('reload lee el token que guardó la capa de datos tras el login',
      () async {
    store.token = token('u2', roles: ['Employee']);
    await controller.reload();
    expect(controller.userId, 'u2');
    expect(controller.isOnlyEmployee, isTrue);
    expect(controller.isOwner, isFalse);
  });

  test('start guarda el token y actualiza el estado', () async {
    await controller.start(token('u3'));
    expect(store.token, isNotNull);
    expect(controller.userId, 'u3');
  });

  test('end borra el token y el estado', () async {
    await controller.start(token('u3'));
    await controller.end();
    expect(store.token, isNull);
    expect(controller.session.value, isNull);
    expect(controller.isLoggedIn, isFalse);
  });

  test('clear solo limpia el estado (sesión vencida por 401)', () async {
    await controller.start(token('u3'));
    controller.clear();
    expect(controller.isLoggedIn, isFalse);
  });

  test('una sesión que vence mientras la app está abierta deja de contar',
      () async {
    var clock = now;
    final shortLived = SessionController(
      SessionService(
        tokenStore: store,
        repository: SessionRepository(store, clock: () => clock),
      ),
      clock: () => clock,
    );
    await shortLived.start(token('u4', expiresIn: const Duration(minutes: 5)));
    expect(shortLived.isLoggedIn, isTrue);
    clock = now.add(const Duration(minutes: 6));
    expect(shortLived.isLoggedIn, isFalse);
  });
}
