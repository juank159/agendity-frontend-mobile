import 'package:flutter_test/flutter_test.dart';
import 'package:login_signup/common/entities/work_hours.dart';
import 'package:login_signup/core/utils/formatters.dart';
import 'package:login_signup/features/appointments/domain/usecases/agenda_hours.dart';
import 'package:login_signup/features/appointments/domain/usecases/free_slots.dart';
import 'package:login_signup/features/appointments/presentation/widgets/agenda_hours_text.dart';

/// Rango de horas y zonas no reservables de la agenda (D-25).
void main() {
  // 2030-01-07 es lunes; 2030-01-13, domingo.
  final monday = DateTime(2030, 1, 7);
  final tuesday = DateTime(2030, 1, 8);
  final saturday = DateTime(2030, 1, 12);
  final sunday = DateTime(2030, 1, 13);

  ScheduleWindow w(int day, String from, String to) =>
      AgendaHours.window(day, WorkHours(start: from, end: to))!;

  /// Lunes a sábado de [from] a [to]; domingo cerrado.
  List<ScheduleWindow> weekdays(String from, String to) =>
      [for (var d = 1; d <= 6; d++) w(d, from, to)];

  const nine = 9 * 60;
  const eight = 20 * 60;

  group('un día', () {
    test('abre de 9 a 20: la vista va de 9 a 20 y no se sombrea nada', () {
      final day = AgendaHours(business: weekdays('09:00', '20:00')).day(monday);
      expect(day.source, AgendaHoursSource.business);
      expect((day.startHour, day.endHour), (9, 20));
      expect(day.closed, isEmpty);
      expect(day.isOpenAt(nine), isTrue);
      expect(day.isOpenAt(eight - 30), isTrue);
      expect(day.isOpenAt(eight), isFalse);
      expect(day.isOpenAt(21 * 60), isFalse);
      expect(day.isClosed, isFalse);
    });

    test(
        'abre 8:30 y cierra 7:15 p. m.: horas completas y sombreado el '
        'resto', () {
      final day = AgendaHours(business: weekdays('08:30', '19:15')).day(monday);
      expect((day.startHour, day.endHour), (8, 20));
      expect(day.closed, const [MinuteSpan(480, 510), MinuteSpan(1155, 1200)]);
      expect(day.isOpenAt(8 * 60), isFalse);
      expect(day.isOpenAt(8 * 60 + 30), isTrue);
    });

    test('franja partida (9–13 y 15–19): el mediodía va sombreado', () {
      final day = AgendaHours(business: [
        w(1, '09:00', '13:00'),
        w(1, '15:00', '19:00'),
      ]).day(monday);
      expect((day.startHour, day.endHour), (9, 19));
      expect(day.closed, const [MinuteSpan(780, 900)]);
      expect(day.isOpenAt(13 * 60), isFalse);
      expect(day.isOpenAt(14 * 60 + 30), isFalse);
      expect(day.isOpenAt(15 * 60), isTrue);
    });

    test('franjas que se tocan se unen', () {
      final day = AgendaHours(business: [
        w(1, '09:00', '12:00'),
        w(1, '12:00', '18:00'),
      ]).day(monday);
      expect(day.open, const [MinuteSpan(540, 1080)]);
      expect(day.closed, isEmpty);
    });

    test(
        'día cerrado: sin horas reservables y el rango de la semana, todo '
        'sombreado', () {
      final hours = AgendaHours(business: weekdays('09:00', '20:00'));
      final day = hours.day(sunday);
      expect(day.isClosed, isTrue);
      expect(day.open, isEmpty);
      expect((day.startHour, day.endHour), (9, 20));
      expect(day.closed, const [MinuteSpan(540, 1200)]);
      expect(day.isOpenAt(10 * 60), isFalse);
    });

    test('cerrado todos los días: rango por defecto, todo sombreado', () {
      final day = const AgendaHours(business: []).day(monday);
      expect(day.isClosed, isTrue);
      expect((day.startHour, day.endHour), (6, 24));
      expect(day.closed, const [MinuteSpan(360, 1440)]);
    });

    test('una cita fuera del horario amplía el rango: nunca se esconde', () {
      final hours = AgendaHours(business: weekdays('09:00', '20:00'));
      final day = hours.day(monday, appointments: [
        (DateTime(2030, 1, 7, 21), DateTime(2030, 1, 7, 22, 10)),
        (DateTime(2030, 1, 7, 7, 30), DateTime(2030, 1, 7, 8)),
        // Otro día: no cuenta.
        (DateTime(2030, 1, 8, 5), DateTime(2030, 1, 8, 6)),
      ]);
      expect((day.startHour, day.endHour), (7, 23));
      // Lo ampliado sigue sin poder reservarse.
      expect(day.closed, const [MinuteSpan(420, 540), MinuteSpan(1200, 1380)]);
    });

    test('una cita en un día cerrado también amplía el rango', () {
      final hours = AgendaHours(business: weekdays('09:00', '18:00'));
      final day = hours.day(sunday, appointments: [
        (DateTime(2030, 1, 13, 18, 30), DateTime(2030, 1, 13, 19, 30)),
      ]);
      expect((day.startHour, day.endHour), (9, 20));
      expect(day.isClosed, isTrue);
    });

    test('una cita que cruza la medianoche llega hasta las 24', () {
      final day = AgendaHours(business: weekdays('09:00', '20:00'))
          .day(monday, appointments: [
        (DateTime(2030, 1, 7, 23), DateTime(2030, 1, 8, 1)),
      ]);
      expect(day.endHour, 24);
    });

    test('abre de 00:00 a 23:55: la vista va de 0 a 24', () {
      final day = AgendaHours(business: [w(1, '00:00', '23:55')]).day(monday);
      expect((day.startHour, day.endHour), (0, 24));
      expect(day.closed, const [MinuteSpan(1435, 1440)]);
    });
  });

  group('sin horario de apertura', () {
    test('se usa la unión de los horarios del equipo', () {
      final hours = AgendaHours(team: [
        [w(1, '09:00', '13:00')],
        [w(1, '12:00', '18:00'), w(2, '10:00', '14:00')],
      ]);
      expect(hours.source, AgendaHoursSource.team);
      final day = hours.day(monday);
      expect(day.open, const [MinuteSpan(540, 1080)]);
      expect((day.startHour, day.endHour), (9, 18));
      // Nadie trabaja el sábado: cerrado.
      expect(hours.day(saturday).isClosed, isTrue);
    });

    test('alguien sin horario atiende a cualquier hora: sin límites', () {
      final hours = AgendaHours(team: [
        [w(1, '09:00', '13:00')],
        const [],
      ]);
      expect(hours.source, AgendaHoursSource.none);
      final day = hours.day(monday);
      expect((day.startHour, day.endHour), (6, 24));
      expect(day.closed, isEmpty);
      expect(day.isOpenAt(23 * 60), isTrue);
      expect(day.isLimited, isFalse);
    });

    test('sin nada: el rango de siempre (6 a 24)', () {
      final day = AgendaHours.unlimited.day(monday);
      expect((day.startHour, day.endHour), (6, 24));
      expect(day.closed, isEmpty);
      expect(day.isClosed, isFalse);
    });
  });

  group('profesional elegido (filtro o la empleada)', () {
    final business = weekdays('09:00', '20:00');

    test(
        'se sombrea también cuando ella no trabaja; el rango sigue siendo '
        'el del negocio', () {
      final day = AgendaHours(business: business)
          .withProfessional([w(1, '10:00', '14:00')]).day(monday);
      expect((day.startHour, day.endHour), (9, 20));
      expect(day.open, const [MinuteSpan(600, 840)]);
      expect(day.closed, const [MinuteSpan(540, 600), MinuteSpan(840, 1200)]);
      expect(day.referenceOpenAt(15 * 60), isTrue);
      expect(day.isOpenAt(15 * 60), isFalse);
    });

    test('el día que no trabaja: libre para el negocio, no para ella', () {
      final day = AgendaHours(business: business)
          .withProfessional([w(1, '10:00', '14:00')]).day(tuesday);
      expect(day.isClosed, isFalse);
      expect(day.professionalOff, isTrue);
      expect(day.closed, const [MinuteSpan(540, 1200)]);
    });

    test('sin horario propio no limita', () {
      final day = AgendaHours(business: business)
          .withProfessional(const []).day(monday);
      expect(day.limitedByProfessional, isFalse);
      expect(day.closed, isEmpty);
    });

    test('sin horario del negocio, manda el de ella', () {
      final day = AgendaHours.unlimited
          .withProfessional([w(1, '10:00', '14:00')]).day(monday);
      expect((day.startHour, day.endHour), (10, 14));
      expect(day.isOpenAt(12 * 60), isTrue);
    });
  });

  group('semana', () {
    test(
        'el rango es la unión de los días abiertos y cada día sombrea lo '
        'suyo', () {
      final hours = AgendaHours(business: [
        w(1, '09:00', '13:00'),
        w(6, '08:00', '12:00'),
      ]);
      final week = hours.week([
        for (var i = 0; i < 7; i++) DateTime(2030, 1, 7 + i),
      ]);
      expect((week.startHour, week.endHour), (8, 13));
      final mon = week.days.first;
      expect(week.closedOf(mon), const [MinuteSpan(480, 540)]);
      final sat = week.days[5];
      expect(week.closedOf(sat), const [MinuteSpan(720, 780)]);
      // Domingo cerrado: todo el rango.
      expect(week.closedOf(week.days.last), const [MinuteSpan(480, 780)]);
      // Martes, también cerrado.
      expect(week.days[1].isClosed, isTrue);
    });

    test('una cita fuera del horario amplía el rango de toda la semana', () {
      final hours = AgendaHours(business: weekdays('09:00', '18:00'));
      final week = hours.week(
        [for (var i = 0; i < 7; i++) DateTime(2030, 1, 7 + i)],
        appointments: [(DateTime(2030, 1, 9, 19), DateTime(2030, 1, 9, 20))],
      );
      expect((week.startHour, week.endHour), (9, 20));
    });
  });

  group('próxima apertura', () {
    test('domingo cerrado → abre el lunes a las 9', () {
      final hours = AgendaHours(business: weekdays('09:00', '20:00'));
      final next = hours.nextOpening(sunday);
      expect(next?.$1, DateTime(2030, 1, 14));
      expect(next?.$2.start, nine);
    });

    test('cerrado siempre: no hay', () {
      expect(const AgendaHours(business: []).nextOpening(sunday), isNull);
    });
  });

  test('horario semanal de un profesional desde sus WorkHours', () {
    final windows = AgendaHours.weekly(const {
      'monday': WorkHours(start: '09:00', end: '13:00'),
      'sunday': WorkHours(start: '10:00', end: '12:00'),
      'otro': WorkHours(start: '10:00', end: '12:00'),
      'tuesday': WorkHours(start: '14:00', end: '10:00'),
    });
    expect(windows.map((x) => (x.dayOfWeek, x.startMinute, x.endMinute)),
        [(1, 540, 780), (7, 600, 720)]);
  });

  group('textos (12 h, palabras simples)', () {
    final today = DateTime(2030, 1, 7, 15);
    final hours = AgendaHours(business: weekdays('09:00', '20:00'));

    test('tocar las 9:00 p. m. de hoy', () {
      final day = hours.day(monday);
      expect(
          AgendaHoursText.closedAt(hours, day, 21 * 60, today),
          'A las ${formatClock(21, 0)} el negocio está cerrado. Hoy atiende '
          'de ${formatClock(9, 0)} a ${formatClock(20, 0)}');
    });

    test('franja partida', () {
      final split = AgendaHours(
          business: [w(1, '09:00', '13:00'), w(1, '15:00', '19:00')]);
      expect(
          AgendaHoursText.closedAt(split, split.day(monday), 14 * 60, today),
          'A las ${formatClock(14, 0)} el negocio está cerrado. Hoy atiende '
          'de ${formatClock(9, 0)} a ${formatClock(13, 0)} y de '
          '${formatClock(15, 0)} a ${formatClock(19, 0)}');
    });

    test('domingo cerrado: abre el lunes', () {
      final day = hours.day(sunday);
      expect(AgendaHoursText.closedDayTitle(day, today),
          'Los domingos el negocio está cerrado');
      expect(AgendaHoursText.nextOpening(hours, day, today),
          'Abre el lunes a las ${formatClock(9, 0)}');
    });

    test('hoy cerrado: abre mañana', () {
      final sundayNow = DateTime(2030, 1, 13, 10);
      final day = hours.day(sunday);
      expect(AgendaHoursText.closedDayTitle(day, sundayNow),
          'Hoy el negocio está cerrado');
      expect(AgendaHoursText.nextOpening(hours, day, sundayNow),
          'Abre mañana a las ${formatClock(9, 0)}');
    });

    test('la empleada: a esa hora no trabaja', () {
      final mine = hours.withProfessional([w(1, '10:00', '14:00')]);
      expect(
          AgendaHoursText.closedAt(mine, mine.day(monday), 16 * 60, today,
              who: ''),
          'A las ${formatClock(16, 0)} no trabajas. Hoy trabajas de '
          '${formatClock(10, 0)} a ${formatClock(14, 0)}');
      expect(
          AgendaHoursText.closedAt(mine, mine.day(monday), 16 * 60, today,
              who: 'Ana Pérez'),
          'A las ${formatClock(16, 0)} Ana Pérez no trabaja. Hoy trabaja de '
          '${formatClock(10, 0)} a ${formatClock(14, 0)}');
    });

    test('plurales de los días', () {
      expect(AgendaHoursText.weekdayPlural(saturday), 'los sábados');
      expect(AgendaHoursText.weekdayPlural(monday), 'los lunes');
    });
  });
}
