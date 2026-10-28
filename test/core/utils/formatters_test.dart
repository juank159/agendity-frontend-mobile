import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:login_signup/core/utils/formatters.dart';

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
    expect(formatTime(d), contains('3:30'));
    expect(formatTime(d).toLowerCase(), contains('p'));
    expect(formatTimeRange(d, d.add(const Duration(minutes: 45))),
        '${formatTime(d)} - ${formatTime(DateTime(2026, 11, 3, 16, 15))}');
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
}
