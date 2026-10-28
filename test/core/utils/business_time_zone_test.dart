import 'package:flutter_test/flutter_test.dart';
import 'package:login_signup/core/utils/business_time_zone.dart';

/// Pasan en cualquier zona del dispositivo (probar con
/// `TZ=Asia/Tokyo flutter test test/core/utils`).
void main() {
  tearDown(() {
    BusinessTimeZone.reset();
    BusinessTimeZone.clock = DateTime.now;
  });

  group('zona actual', () {
    test('sin sesión, la por defecto del backend', () {
      expect(BusinessTimeZone.current, 'America/Bogota');
    });

    test('use: canónica, sin mayúsculas ni espacios; desconocida no cambia',
        () {
      expect(BusinessTimeZone.use(' america/caracas '), true);
      expect(BusinessTimeZone.current, 'America/Caracas');
      expect(BusinessTimeZone.use('Marte/Olympus'), false);
      expect(BusinessTimeZone.use(null), false);
      expect(BusinessTimeZone.use(''), false);
      expect(BusinessTimeZone.current, 'America/Caracas');
      BusinessTimeZone.reset();
      expect(BusinessTimeZone.current, BusinessTimeZone.fallback);
    });

    test('isValid y canonicalName', () {
      expect(BusinessTimeZone.isValid('Europe/Madrid'), true);
      expect(BusinessTimeZone.isValid('UTC'), true);
      expect(BusinessTimeZone.isValid('GMT-5'), false);
      expect(BusinessTimeZone.canonicalName('AMERICA/BOGOTA'),
          'America/Bogota');
    });

    test('names: ordenadas, con las de Colombia y Venezuela, sin alias', () {
      final names = BusinessTimeZone.names;
      expect(names, containsAll(['America/Bogota', 'America/Caracas', 'UTC']));
      expect(names, isNot(contains('US/Eastern')));
      expect(names, orderedEquals([...names]..sort()));
    });

    test('utcOffset: Bogotá −5 h y Caracas −4 h', () {
      final at = DateTime.utc(2026, 10, 21, 12);
      expect(BusinessTimeZone.utcOffset('America/Bogota', at),
          const Duration(hours: -5));
      expect(BusinessTimeZone.utcOffset('America/Caracas', at),
          const Duration(hours: -4));
      BusinessTimeZone.use('America/Caracas');
      expect(BusinessTimeZone.utcOffset(null, at), const Duration(hours: -4));
    });
  });

  group('conversiones', () {
    final instant = DateTime.utc(2026, 10, 21, 13); // 08:00 Bogotá, 09:00 Caracas

    test('toWallClock en la zona del negocio o en la indicada', () {
      expect(BusinessTimeZone.toWallClock(instant), DateTime(2026, 10, 21, 8));
      expect(BusinessTimeZone.toWallClock(instant, 'America/Caracas'),
          DateTime(2026, 10, 21, 9));
      expect(BusinessTimeZone.toWallClock(instant).isUtc, false);
    });

    test('toInstant es la inversa; un UTC se devuelve igual', () {
      expect(BusinessTimeZone.toInstant(DateTime(2026, 10, 21, 8)), instant);
      expect(
          BusinessTimeZone.toInstant(
              DateTime(2026, 10, 21, 9), 'America/Caracas'),
          instant);
      expect(BusinessTimeZone.toInstant(instant), same(instant));
    });

    test('zona desconocida cuenta como la del negocio', () {
      expect(BusinessTimeZone.toWallClock(instant, 'Marte/Olympus'),
          DateTime(2026, 10, 21, 8));
    });

    test('horario de verano: Madrid en invierno y en verano', () {
      expect(
          BusinessTimeZone.toWallClock(
              DateTime.utc(2026, 1, 15, 12), 'Europe/Madrid'),
          DateTime(2026, 1, 15, 13));
      expect(
          BusinessTimeZone.toWallClock(
              DateTime.utc(2026, 7, 15, 12), 'Europe/Madrid'),
          DateTime(2026, 7, 15, 14));
    });
  });

  group('ahora y hoy del negocio', () {
    test('a las 04:30Z del 22 es el 21 en Bogotá y el 22 en Caracas', () {
      BusinessTimeZone.clock = () => DateTime.utc(2026, 10, 22, 4, 30);
      expect(BusinessTimeZone.now(), DateTime(2026, 10, 21, 23, 30));
      expect(BusinessTimeZone.today(), DateTime(2026, 10, 21));
      BusinessTimeZone.use('America/Caracas');
      expect(BusinessTimeZone.now(), DateTime(2026, 10, 22, 0, 30));
      expect(BusinessTimeZone.today(), DateTime(2026, 10, 22));
    });
  });
}
