import 'package:flutter_test/flutter_test.dart';
import 'package:login_signup/core/utils/date_codec.dart';

/// Pasan en cualquier zona del dispositivo. Para probar otras zonas:
/// `TZ=Asia/Tokyo flutter test test/core/utils` (también UTC,
/// America/Bogota, Pacific/Kiritimati +14 y Pacific/Pago_Pago −11).
void main() {
  final offset = DateTime(2026, 10, 21).timeZoneOffset;

  group('encode', () {
    test('siempre UTC con Z, mismo instante', () {
      final local = DateTime(2026, 10, 21, 8, 30);
      final encoded = DateCodec.encode(local);
      expect(encoded, endsWith('Z'));
      expect(DateTime.parse(encoded), local.toUtc());
      expect(DateTime.parse(encoded).isAtSameMomentAs(local), true);
    });

    test('una fecha ya en UTC no cambia', () {
      expect(DateCodec.encode(DateTime.utc(2026, 10, 21, 13)),
          '2026-10-21T13:00:00.000Z');
    });

    test('encodeOrNull', () {
      expect(DateCodec.encodeOrNull(null), isNull);
      expect(DateCodec.encodeOrNull(DateTime.utc(2026)),
          '2026-01-01T00:00:00.000Z');
    });

    test('ida y vuelta conserva el instante y la hora local', () {
      final local = DateTime(2026, 12, 31, 23, 59, 59, 999);
      final back = DateCodec.decode(DateCodec.encode(local));
      expect(back, local);
      expect(back.isUtc, false);
    });
  });

  group('decode', () {
    test('ISO con el offset del negocio (formato del backend desde 2.05)', () {
      final decoded = DateCodec.decode('2026-10-21T08:00:00.000-05:00');
      expect(decoded.isUtc, false);
      expect(decoded.isAtSameMomentAs(DateTime.utc(2026, 10, 21, 13)), true);
      expect(decoded, DateTime.utc(2026, 10, 21, 13).toLocal());
    });

    test('ISO en UTC (formato antiguo) da el mismo instante', () {
      expect(DateCodec.decode('2026-10-21T13:00:00.000Z'),
          DateCodec.decode('2026-10-21T08:00:00.000-05:00'));
    });

    test('solo fecha → medianoche local de ese día', () {
      final day = DateCodec.decode('2026-10-21');
      expect([day.year, day.month, day.day, day.hour], [2026, 10, 21, 0]);
    });

    test('espacios alrededor', () {
      expect(DateCodec.decode(' 2026-10-21T13:00:00Z '),
          DateTime.utc(2026, 10, 21, 13).toLocal());
    });

    test('inválida lanza FormatException', () {
      expect(() => DateCodec.decode('ayer'), throwsFormatException);
    });

    test('tryDecode: null, vacío, inválido, número → null', () {
      for (final value in [null, '', '  ', 'ayer', 123]) {
        expect(DateCodec.tryDecode(value), isNull, reason: '$value');
      }
    });

    test('tryDecode: texto válido y DateTime', () {
      expect(DateCodec.tryDecode('2026-10-21T13:00:00Z'),
          DateTime.utc(2026, 10, 21, 13).toLocal());
      final utc = DateTime.utc(2026, 10, 21, 13);
      expect(DateCodec.tryDecode(utc)!.isUtc, false);
      expect(DateCodec.tryDecode(utc)!.isAtSameMomentAs(utc), true);
    });
  });

  group('cambio de día alrededor de medianoche', () {
    test('23:30 de Bogotá es el día siguiente en UTC, y se envía así', () {
      // 21-oct 23:30 en Bogotá = 22-oct 04:30Z.
      final instant = DateCodec.decode('2026-10-21T23:30:00.000-05:00');
      expect(DateCodec.encode(instant), '2026-10-22T04:30:00.000Z');
    });

    test('el día local depende de la zona del dispositivo', () {
      final instant = DateCodec.decode('2026-10-21T23:30:00.000-05:00');
      final expectedDay =
          DateTime.utc(2026, 10, 22, 4, 30).add(offset); // reloj local
      expect(instant.day, expectedDay.day);
      expect(instant.hour, expectedDay.hour);
      if (offset == const Duration(hours: -5)) {
        expect([instant.day, instant.hour, instant.minute], [21, 23, 30]);
      }
      if (offset == Duration.zero) {
        expect([instant.day, instant.hour], [22, 4]);
      }
    });

    test('medianoche local enviada y recibida sigue siendo medianoche', () {
      final midnight = DateTime(2026, 10, 22);
      final back = DateCodec.decode(DateCodec.encode(midnight));
      expect([back.day, back.hour, back.minute], [22, 0, 0]);
    });
  });

  group('encodeDay (rangos de estadísticas)', () {
    test('día de calendario local, sin convertir de zona', () {
      expect(DateCodec.encodeDay(DateTime(2026, 1, 5, 23, 59)), '2026-01-05');
      expect(DateCodec.encodeDay(DateTime(2026, 10, 21)), '2026-10-21');
    });

    test('a las 23:59 locales no salta al día siguiente aunque en UTC sí', () {
      final lateNight = DateTime(2026, 10, 21, 23, 59);
      expect(DateCodec.encodeDay(lateNight), '2026-10-21');
    });
  });
}
