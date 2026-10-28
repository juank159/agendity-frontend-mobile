import 'package:flutter_test/flutter_test.dart';
import 'package:login_signup/core/utils/business_time_zone.dart';
import 'package:login_signup/core/utils/date_codec.dart';

/// Pasan en cualquier zona del dispositivo: las horas son las del negocio
/// (D-15), no las del teléfono. Para probarlo:
/// `TZ=Asia/Tokyo flutter test test/core/utils` (también UTC,
/// America/Caracas, Pacific/Kiritimati +14 y Pacific/Pago_Pago −11).
void main() {
  setUp(() => BusinessTimeZone.use('America/Bogota'));
  tearDown(BusinessTimeZone.reset);

  group('encode (hora de pared del negocio → instante UTC)', () {
    test('las 08:30 de Bogotá son las 13:30Z, con el teléfono donde sea', () {
      final encoded = DateCodec.encode(DateTime(2026, 10, 21, 8, 30));
      expect(encoded, '2026-10-21T13:30:00.000Z');
    });

    test('negocio en Caracas: la misma hora de pared es otro instante', () {
      BusinessTimeZone.use('America/Caracas');
      expect(DateCodec.encode(DateTime(2026, 10, 21, 8, 30)),
          '2026-10-21T12:30:00.000Z');
    });

    test('una fecha ya en UTC es un instante y no cambia', () {
      expect(DateCodec.encode(DateTime.utc(2026, 10, 21, 13)),
          '2026-10-21T13:00:00.000Z');
    });

    test('encodeOrNull', () {
      expect(DateCodec.encodeOrNull(null), isNull);
      expect(DateCodec.encodeOrNull(DateTime.utc(2026)),
          '2026-01-01T00:00:00.000Z');
    });

    test('ida y vuelta conserva la hora de pared', () {
      final wall = DateTime(2026, 12, 31, 23, 59, 59, 999);
      final back = DateCodec.decode(DateCodec.encode(wall));
      expect(back, wall);
      expect(back.isUtc, false);
    });
  });

  group('decode (instante → hora de pared del negocio)', () {
    test('ISO con el offset del negocio (formato del backend desde 2.05)', () {
      final decoded = DateCodec.decode('2026-10-21T08:00:00.000-05:00');
      expect(decoded.isUtc, false);
      expect(decoded, DateTime(2026, 10, 21, 8));
    });

    test('ISO en UTC da la misma hora de pared', () {
      expect(DateCodec.decode('2026-10-21T13:00:00.000Z'),
          DateTime(2026, 10, 21, 8));
    });

    test('negocio en Caracas: el mismo instante es una hora más', () {
      BusinessTimeZone.use('America/Caracas');
      expect(DateCodec.decode('2026-10-21T08:00:00.000-05:00'),
          DateTime(2026, 10, 21, 9));
    });

    test('con la zona del registro manda la del registro', () {
      BusinessTimeZone.use('America/Caracas');
      // Cita creada cuando el negocio estaba en Bogotá (6.03).
      expect(
          DateCodec.decode('2026-10-21T08:00:00.000-05:00',
              timeZone: 'America/Bogota'),
          DateTime(2026, 10, 21, 8));
      expect(
          DateCodec.tryDecode('2026-10-21T13:00:00Z',
              timeZone: 'america/bogota'),
          DateTime(2026, 10, 21, 8));
    });

    test('zona del registro desconocida: la hora escrita (su offset)', () {
      expect(
          DateCodec.decode('2026-10-21T09:00:00.000-04:00',
              timeZone: 'Marte/Olympus'),
          DateTime(2026, 10, 21, 9));
    });

    test('sin offset (fuera del contrato) ya es hora del negocio', () {
      expect(DateCodec.decode('2026-10-21T08:00:00'),
          DateTime(2026, 10, 21, 8));
    });

    test('solo fecha → medianoche de ese día', () {
      final day = DateCodec.decode('2026-10-21');
      expect([day.year, day.month, day.day, day.hour], [2026, 10, 21, 0]);
    });

    test('espacios alrededor', () {
      expect(DateCodec.decode(' 2026-10-21T13:00:00Z '),
          DateTime(2026, 10, 21, 8));
    });

    test('inválida lanza FormatException', () {
      expect(() => DateCodec.decode('ayer'), throwsFormatException);
    });

    test('tryDecode: null, vacío, inválido, número → null', () {
      for (final value in [null, '', '  ', 'ayer', 123]) {
        expect(DateCodec.tryDecode(value), isNull, reason: '$value');
      }
    });

    test('tryDecode: DateTime UTC → hora de pared; no UTC → igual', () {
      final utc = DateTime.utc(2026, 10, 21, 13);
      expect(DateCodec.tryDecode(utc), DateTime(2026, 10, 21, 8));
      final wall = DateTime(2026, 10, 21, 8);
      expect(DateCodec.tryDecode(wall), same(wall));
    });
  });

  group('cambio de día alrededor de medianoche', () {
    test('23:30 de Bogotá es el día siguiente en UTC, y se envía así', () {
      final wall = DateCodec.decode('2026-10-21T23:30:00.000-05:00');
      expect([wall.day, wall.hour, wall.minute], [21, 23, 30]);
      expect(DateCodec.encode(wall), '2026-10-22T04:30:00.000Z');
    });

    test('el día lo decide la zona del negocio, no la del dispositivo', () {
      // 22-oct 04:30Z: en Bogotá todavía es el 21; en Caracas, 00:30 del 22.
      expect(DateCodec.decode('2026-10-22T04:30:00Z').day, 21);
      BusinessTimeZone.use('America/Caracas');
      final caracas = DateCodec.decode('2026-10-22T04:30:00Z');
      expect([caracas.day, caracas.hour, caracas.minute], [22, 0, 30]);
    });

    test('medianoche enviada y recibida sigue siendo medianoche', () {
      final midnight = DateTime(2026, 10, 22);
      final back = DateCodec.decode(DateCodec.encode(midnight));
      expect([back.day, back.hour, back.minute], [22, 0, 0]);
    });
  });

  group('encodeDay (rangos de estadísticas)', () {
    test('día de calendario del negocio, sin convertir de zona', () {
      expect(DateCodec.encodeDay(DateTime(2026, 1, 5, 23, 59)), '2026-01-05');
      expect(DateCodec.encodeDay(DateTime(2026, 10, 21)), '2026-10-21');
    });

    test('a las 23:59 no salta al día siguiente aunque en UTC sí', () {
      final lateNight = DateTime(2026, 10, 21, 23, 59);
      expect(DateCodec.encodeDay(lateNight), '2026-10-21');
    });
  });

  group('tryDecodeDay (días del negocio)', () {
    test('"YYYY-MM-DD" → medianoche de ese día, ida y vuelta', () {
      final day = DateCodec.tryDecodeDay('2026-10-21')!;
      expect(day, DateTime(2026, 10, 21));
      expect(day.isUtc, false);
      expect(DateCodec.encodeDay(day), '2026-10-21');
    });

    test(
        'instante con offset del negocio → la fecha escrita, en cualquier zona',
        () {
      // Fin del día en Bogotá: en UTC (o Tokio) ya es el día 22.
      expect(DateCodec.tryDecodeDay('2026-10-21T23:59:59.999-05:00'),
          DateTime(2026, 10, 21));
      expect(DateCodec.tryDecodeDay('2026-10-21T00:00:00.000-05:00'),
          DateTime(2026, 10, 21));
    });

    test('DateTime → solo su día', () {
      expect(DateCodec.tryDecodeDay(DateTime(2026, 1, 5, 18, 30)),
          DateTime(2026, 1, 5));
    });

    test('null, vacío, basura o día imposible → null', () {
      for (final value in [null, '', 'hoy', '21-10-2026', '2026-02-30', 5]) {
        expect(DateCodec.tryDecodeDay(value), isNull, reason: '$value');
      }
    });
  });
}
