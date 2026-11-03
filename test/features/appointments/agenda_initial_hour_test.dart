import 'package:flutter_test/flutter_test.dart';
import 'package:login_signup/core/utils/business_time_zone.dart';
import 'package:login_signup/features/appointments/presentation/widgets/appointment_calendar.dart';

void main() {
  final original = BusinessTimeZone.clock;
  tearDown(() => BusinessTimeZone.clock = original);

  void at(DateTime wall) =>
      BusinessTimeZone.clock = () => BusinessTimeZone.toInstant(wall);

  test('hoy por la tarde: la agenda abre una hora antes de ahora', () {
    at(DateTime(2026, 11, 2, 18, 2));
    final d =
        AppointmentCalendar.initialDisplayDateFor(DateTime(2026, 11, 2));
    expect(d, DateTime(2026, 11, 2, 17));
  });

  test('hoy de madrugada: no antes del inicio de la vista', () {
    at(DateTime(2026, 11, 2, 3, 0));
    final d =
        AppointmentCalendar.initialDisplayDateFor(DateTime(2026, 11, 2));
    expect(d.hour, AppointmentCalendar.startHour);
  });

  test('otro día: se abre al inicio', () {
    at(DateTime(2026, 11, 2, 18, 2));
    final day = DateTime(2026, 11, 3);
    expect(AppointmentCalendar.initialDisplayDateFor(day), day);
  });
}
