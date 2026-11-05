import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:login_signup/core/utils/business_time_zone.dart';
import 'package:login_signup/core/utils/formatters.dart';

/// "9:30 a. m." con los espacios de no separación del formateador.
String clock(String text) => text.replaceAll(' ', '\u00a0');

void main() {
  setUpAll(() => initializeDateFormatting('es'));

  group('formatCop', () {
    test('agrupa con punto y sin decimales', () {
      expect(formatCop(45000), '\$ 45.000');
      expect(formatCop(1234567.6), '\$ 1.234.568');
      expect(formatCop(0), '\$ 0');
    });
    test('acepta texto numérico, null y negativos', () {
      expect(formatCop('45000.00'), '\$ 45.000');
      expect(formatCop(null), '\$ 0');
      expect(formatCop('abc'), '\$ 0');
      expect(formatCop(-1500), '-\$ 1.500');
    });
  });

  test('formatMoney: COP o código y dos decimales', () {
    expect(formatMoney(20000, currency: 'cop'), '\$ 20.000');
    expect(formatMoney(12.5, currency: 'USD'), 'USD 12.50');
  });

  test('fechas y horas en español', () {
    final d = DateTime(2026, 11, 3, 15, 30);
    expect(formatDate(d), '03/11/2026');
    expect(formatShortDate(d), '03/11/26');
    expect(formatWeekdayDayMonth(d), 'martes 3 noviembre');
    expect(formatLongDate(d), 'martes, 03 noviembre 2026');
    expect(formatTime(d), clock('3:30 p. m.'));
  });

  group('parseCop y formatCopDigits (D-24)', () {
    test('formatCopDigits: miles con punto, sin símbolo', () {
      expect(formatCopDigits(0), '0');
      expect(formatCopDigits(999), '999');
      expect(formatCopDigits(15000), '15.000');
      expect(formatCopDigits(1234567), '1.234.567');
      expect(formatCopDigits(-1500), '-1.500');
    });

    test('formatCop usa la misma agrupación', () {
      expect(formatCop(15000), '\$ ${formatCopDigits(15000)}');
    });

    test('parseCop: lo escrito, lo pegado y lo formateado', () {
      for (final (text, amount) in [
        ('15000', 15000),
        ('15.000', 15000),
        (r'$ 15.000', 15000),
        (r'$15.000', 15000),
        (' 15 000 ', 15000),
        ('15.000,50', 15000),
        ('15.000,5', 15000),
        ('45000.00', 45000),
        ('0', 0),
        ('000', 0),
        ('007', 7),
        ('1.234.567', 1234567),
        (formatCop(250000), 250000),
      ]) {
        expect(parseCop(text), amount, reason: text);
      }
    });

    test('parseCop: sin monto → null', () {
      for (final text in [null, '', '   ', r'$', 'abc', '-5000', '\$ -1']) {
        expect(parseCop(text), isNull, reason: '$text');
      }
      expect(parseCop('9' * copMaxDigits), int.parse('9' * copMaxDigits));
      expect(parseCop('9' * (copMaxDigits + 1)), isNull);
    });

    test('ida y vuelta', () {
      for (final amount in [0, 1, 999, 1000, 45000, 1500000, 999999999]) {
        expect(parseCop(formatCopDigits(amount)), amount);
        expect(parseCop(formatCop(amount)), amount);
      }
    });

    test('copDigitsOf y dropCopDecimals', () {
      expect(copDigitsOf(r'$ 0.015.000'), '15000');
      expect(copDigitsOf('00'), '0');
      expect(copDigitsOf('abc'), '');
      expect(copDigitsOf('15.000,50'), '1500050');
      expect(copDigitsOf('15.000,50', dropDecimals: true), '15000');
      expect(dropCopDecimals('1.500'), '1.500');
      expect(dropCopDecimals('1.50'), '1');
    });
  });

  group('horas en 12 h (D-23)', () {
    tearDown(BusinessTimeZone.reset);

    test('formatClock: los bordes del día', () {
      expect(formatClock(0, 0), clock('12:00 a. m.'));
      expect(formatClock(0, 5), clock('12:05 a. m.'));
      expect(formatClock(1, 0), clock('1:00 a. m.'));
      expect(formatClock(9, 30), clock('9:30 a. m.'));
      expect(formatClock(11, 59), clock('11:59 a. m.'));
      expect(formatClock(12, 0), clock('12:00 p. m.'));
      expect(formatClock(12, 5), clock('12:05 p. m.'));
      expect(formatClock(13, 0), clock('1:00 p. m.'));
      expect(formatClock(23, 59), clock('11:59 p. m.'));
    });

    test('las 1440 horas del día: 12 h, minutos con dos cifras, sufijo', () {
      for (var h = 0; h < 24; h++) {
        for (var m = 0; m < 60; m++) {
          final text = formatClock(h, m);
          final hour12 = h % 12 == 0 ? 12 : h % 12;
          expect(
              text,
              '$hour12:${m.toString().padLeft(2, '0')}\u00a0'
              '${h < 12 ? timeAmLabel : timePmLabel}');
        }
      }
    });

    test('sufijos y espacios de no separación', () {
      expect(timeAmLabel, clock('a. m.'));
      expect(timePmLabel, clock('p. m.'));
      expect(formatClock(9, 30).contains(' '), isFalse);
    });

    test('formatClock: fuera de rango → error', () {
      expect(() => formatClock(24, 0), throwsArgumentError);
      expect(() => formatClock(-1, 0), throwsArgumentError);
      expect(() => formatClock(10, 60), throwsArgumentError);
    });

    test('formatTimeOfDay', () {
      expect(formatTimeOfDay(const TimeOfDay(hour: 9, minute: 30)),
          clock('9:30 a. m.'));
      expect(formatTimeOfDay(const TimeOfDay(hour: 0, minute: 5)),
          clock('12:05 a. m.'));
      expect(formatTimeOfDay(const TimeOfDay(hour: 12, minute: 0)),
          clock('12:00 p. m.'));
    });

    test('formatHhmm: horas del contrato; lo que no es hora, igual', () {
      expect(formatHhmm('09:00'), clock('9:00 a. m.'));
      expect(formatHhmm('9:00'), clock('9:00 a. m.'));
      expect(formatHhmm('19:30'), clock('7:30 p. m.'));
      expect(formatHhmm('00:00:00'), clock('12:00 a. m.'));
      expect(formatHhmm(' 12:15 '), clock('12:15 p. m.'));
      for (final text in ['', 'abc', '24:00', '10:60', '10', '10:5']) {
        expect(formatHhmm(text), text.trim(), reason: text);
      }
    });

    test('formatTime: hora de pared tal cual; UTC en la zona del negocio', () {
      expect(formatTime(DateTime(2026, 11, 3, 0, 5)), clock('12:05 a. m.'));
      BusinessTimeZone.use('America/Bogota');
      expect(
          formatTime(DateTime.utc(2026, 11, 3, 14, 30)), clock('9:30 a. m.'));
      BusinessTimeZone.use('America/Caracas');
      expect(
          formatTime(DateTime.utc(2026, 11, 3, 14, 30)), clock('10:30 a. m.'));
      BusinessTimeZone.use('Asia/Tokyo');
      expect(
          formatTime(DateTime.utc(2026, 11, 3, 14, 30)), clock('11:30 p. m.'));
    });

    test('formatTimeRange: sufijo una vez si es el mismo periodo', () {
      DateTime at(int h, int m) => DateTime(2026, 11, 3, h, m);
      expect(formatTimeRange(at(10, 0), at(11, 5)),
          '10:00 – ${clock('11:05 a. m.')}');
      expect(formatTimeRange(at(15, 30), at(16, 15)),
          '3:30 – ${clock('4:15 p. m.')}');
      expect(formatTimeRange(at(11, 30), at(13, 0)),
          '${clock('11:30 a. m.')} – ${clock('1:00 p. m.')}');
      expect(formatTimeRange(at(23, 30), DateTime(2026, 11, 4, 0, 30)),
          '${clock('11:30 p. m.')} – ${clock('12:30 a. m.')}');
    });
  });

  test('formatCount: singular solo con 1', () {
    expect(formatCount(1, 'cita', 'citas'), '1 cita');
    expect(formatCount(0, 'cita', 'citas'), '0 citas');
    expect(formatCount(3, 'pago', 'pagos'), '3 pagos');
  });

  test('formatDurationMinutes: minutos y horas', () {
    expect(formatDurationMinutes(45), '45 min');
    expect(formatDurationMinutes(60), '1 h');
    expect(formatDurationMinutes(75), '1 h 15 min');
    expect(formatDurationMinutes(-5), '0 min');
  });

  test('formatPercent: de 0 a 100, un decimal como mucho', () {
    expect(formatPercent(15), '15 %');
    expect(formatPercent(12.46), '12,5 %');
    expect(formatPercent(1250), '1.250 %');
    expect(formatPercent(null), '0 %');
  });

  test(
      'dayMomentOf y formatHhmmWithMoment: el 12 dice si es mediodía o medianoche',
      () {
    expect(dayMomentOf(0), 'medianoche');
    expect(dayMomentOf(3), 'de la madrugada');
    expect(dayMomentOf(8), 'de la mañana');
    expect(dayMomentOf(12), 'mediodía');
    expect(dayMomentOf(14), 'de la tarde');
    expect(dayMomentOf(20), 'de la noche');
    expect(formatHhmmWithMoment('12:00'), '${formatHhmm('12:00')} (mediodía)');
    expect(
        formatHhmmWithMoment('00:30'), '${formatHhmm('00:30')} (medianoche)');
    expect(formatHhmmWithMoment('08:00'), formatHhmm('08:00'));
    expect(formatHhmmWithMoment('abc'), 'abc');
  });
}
