import 'package:flutter_test/flutter_test.dart';
import 'package:login_signup/core/session/session_repository.dart';
import 'package:login_signup/core/session/session_service.dart';
import 'package:login_signup/core/utils/business_time_zone.dart';

import 'jwt_helper.dart';
import 'memory_token_store.dart';

/// Zona del negocio en la sesión (D-15, 6.04).
void main() {
  final now = DateTime.utc(2026, 10, 23, 12);
  late MemoryTokenStore tokens;
  late MemoryTimeZoneStore zones;
  late SessionService service;
  late int loads;
  String? backendZone;
  Exception? loadError;

  String token(String id, {Duration expiresIn = const Duration(hours: 1)}) =>
      fakeJwt({
        'id': id,
        'roles': ['Owner'],
        'exp': epochSeconds(now.add(expiresIn))
      });

  setUp(() {
    tokens = MemoryTokenStore();
    zones = MemoryTimeZoneStore();
    loads = 0;
    backendZone = 'America/Caracas';
    loadError = null;
    service = SessionService(
      tokenStore: tokens,
      repository: SessionRepository(tokens, clock: () => now),
      timeZoneStore: zones,
      loadTimeZone: () async {
        loads++;
        if (loadError != null) throw loadError!;
        return backendZone;
      },
    );
  });

  tearDown(BusinessTimeZone.reset);

  test('start: carga la zona de /auth/me y la fija para toda la app',
      () async {
    final session = await service.start(token('u1'));
    expect(loads, 1);
    expect(session.timeZone, 'America/Caracas');
    expect(service.timeZone, 'America/Caracas');
    expect(BusinessTimeZone.current, 'America/Caracas');
    expect(zones.timeZone, 'America/Caracas');
    expect((await service.current())!.timeZone, 'America/Caracas');
  });

  test('restore (auto-login): carga la zona', () async {
    tokens.token = token('u1');
    final session = await service.restore();
    expect(session!.timeZone, 'America/Caracas');
    expect(BusinessTimeZone.current, 'America/Caracas');
  });

  test('sin red: la última guardada; sin guardada, la por defecto', () async {
    loadError = Exception('sin red');
    zones.timeZone = 'America/Caracas';
    tokens.token = token('u1');
    expect((await service.restore())!.timeZone, 'America/Caracas');
    expect(BusinessTimeZone.current, 'America/Caracas');

    await service.end();
    zones.timeZone = null;
    final session = await service.start(token('u2'));
    expect(session.timeZone, isNull);
    expect(BusinessTimeZone.current, BusinessTimeZone.fallback);
  });

  test('zona desconocida del backend: se ignora', () async {
    backendZone = 'Marte/Olympus';
    final session = await service.start(token('u1'));
    expect(session.timeZone, isNull);
    expect(BusinessTimeZone.current, BusinessTimeZone.fallback);
  });

  test('end y sesión vencida: vuelven a la zona por defecto y la borran',
      () async {
    await service.start(token('u1'));
    await service.end();
    expect(service.timeZone, isNull);
    expect(zones.timeZone, isNull);
    expect(BusinessTimeZone.current, BusinessTimeZone.fallback);

    final expired = token('u1');
    await service.start(expired);
    await service.handleSessionExpired(expired);
    expect(BusinessTimeZone.current, BusinessTimeZone.fallback);

    loads = 0;
    tokens.token = token('u1', expiresIn: const Duration(hours: -1));
    zones.timeZone = 'America/Caracas';
    expect(await service.restore(), isNull);
    expect(zones.timeZone, isNull);
    expect(loads, 0, reason: 'sin sesión no se pide /auth/me');
  });

  test('applyTimeZone (cambio en la configuración): canónica y guardada',
      () async {
    await service.start(token('u1'));
    await service.applyTimeZone('america/bogota');
    expect(service.timeZone, 'America/Bogota');
    expect(BusinessTimeZone.current, 'America/Bogota');
    expect(zones.timeZone, 'America/Bogota');
    expect((await service.current())!.timeZone, 'America/Bogota');

    await service.applyTimeZone('Marte/Olympus');
    expect(service.timeZone, 'America/Bogota');
  });

  test('restore: si /auth/me cerró la sesión (401), no hay sesión', () async {
    final stored = token('u1');
    tokens.token = stored;
    service.loadTimeZone = () async {
      await service.handleSessionExpired(stored);
      return null;
    };
    expect(await service.restore(), isNull);
    expect(tokens.token, isNull);
  });

  test('la sesión con otra zona es otra (la UI se entera del cambio)', () {
    final session = SessionRepository.decode(token('u1'))!;
    expect(session.withTimeZone('America/Caracas'), isNot(session));
    expect(session.withTimeZone(null), same(session));
  });
}
