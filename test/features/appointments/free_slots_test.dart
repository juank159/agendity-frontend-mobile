import 'package:flutter_test/flutter_test.dart';
import 'package:login_signup/features/appointments/domain/usecases/free_slots.dart';

/// Horas libres calculadas en la app (`FreeSlots`, sin conexión) con D-26:
/// la apertura del negocio es un solo tramo por día (el almuerzo solo cierra
/// el link público); el horario del profesional conserva sus franjas.
void main() {
  // 2030-01-07 es lunes.
  final monday = DateTime(2030, 1, 7);
  final now = DateTime(2030, 1, 7, 6);

  ScheduleWindow w(int day, int fromHour, int toHour, {int fromMinute = 0}) =>
      ScheduleWindow(day, fromHour * 60 + fromMinute, toHour * 60);

  /// Lunes de 8:00 a 12:00 y de 14:00 a 19:00 (almuerzo de 12 a 2).
  final lunchBreak = [w(1, 8, 12), w(1, 14, 19)];

  List<DateTime> slots({
    List<ScheduleWindow> professional = const [],
    List<ScheduleWindow>? business,
    List<BusyInterval> busy = const [],
    int duration = 30,
  }) =>
      FreeSlots.compute(
        day: monday,
        durationMinutes: duration,
        stepMinutes: 30,
        professionalWindows: professional,
        businessWindows: business,
        busy: busy,
        now: now,
      );

  DateTime at(int hour, [int minute = 0]) => DateTime(2030, 1, 7, hour, minute);

  group('ScheduleWindow.daySpans', () {
    test('un tramo por día, de la primera apertura al último cierre', () {
      final spans = ScheduleWindow.daySpans([
        w(2, 9, 18),
        w(1, 14, 19),
        w(1, 8, 12),
        w(1, 10, 11), // dentro: no cambia nada
        const ScheduleWindow(3, 600, 600), // vacía: se ignora
      ]);
      expect(spans.map((s) => (s.dayOfWeek, s.startMinute, s.endMinute)),
          [(1, 480, 1140), (2, 540, 1080)]);
    });

    test('sin franjas: sin días (cerrado)', () {
      expect(ScheduleWindow.daySpans(const []), isEmpty);
    });
  });

  group('FreeSlots con el almuerzo del negocio (D-26)', () {
    test('el hueco del almuerzo ofrece horas en la app', () {
      final result = slots(business: lunchBreak);
      expect(result, containsAll([at(12), at(12, 30), at(13), at(13, 30)]));
      // Una cita que cruza el almuerzo también cabe.
      expect(slots(business: lunchBreak, duration: 180), contains(at(11)));
    });

    test('antes de abrir y después de cerrar, no', () {
      final result = slots(business: lunchBreak);
      expect(result.first, at(8));
      expect(result.last, at(18, 30));
      expect(result, isNot(contains(at(7, 30))));
      expect(result, isNot(contains(at(19))));
      // Abre a las 8:30: las 8:00 no.
      final opensLate =
          slots(business: [w(1, 8, 12, fromMinute: 30), w(1, 14, 19)]);
      expect(opensLate.first, at(8, 30));
    });

    test('un día sin franjas sigue cerrado', () {
      expect(slots(business: [w(2, 8, 19)]), isEmpty);
      expect(slots(business: const []), isEmpty);
    });

    test('el almuerzo propio de la profesional sí cuenta', () {
      final result = slots(
          business: lunchBreak, professional: [w(1, 8, 12), w(1, 13, 19)]);
      expect(result, isNot(contains(at(12))));
      expect(result, isNot(contains(at(12, 30))));
      expect(result, containsAll([at(13), at(13, 30)]));
    });

    test('lo ocupado sigue valiendo en el almuerzo', () {
      final result =
          slots(business: lunchBreak, busy: [BusyInterval(at(12), at(13))]);
      expect(result, isNot(contains(at(12))));
      expect(result, isNot(contains(at(12, 30))));
      expect(result, contains(at(13)));
    });
  });
}
