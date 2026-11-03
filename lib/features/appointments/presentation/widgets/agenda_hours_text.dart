import 'package:login_signup/core/utils/formatters.dart';
import 'package:login_signup/features/appointments/domain/usecases/agenda_hours.dart';

/// Textos del horario de la agenda (D-25), en palabras simples y con horas en
/// 12 h (`formatClock`, D-23).
///
/// [who] es el profesional del filtro: `null` = el negocio; `''` = la
/// empleada que mira su agenda ("tú").
abstract final class AgendaHoursText {
  static const _weekdays = [
    'lunes',
    'martes',
    'miércoles',
    'jueves',
    'viernes',
    'sábado',
    'domingo',
  ];

  /// `lunes`, `sábado`…
  static String weekday(DateTime day) => _weekdays[day.weekday - 1];

  /// `los lunes`, `los sábados`…
  static String weekdayPlural(DateTime day) {
    final name = weekday(day);
    return 'los ${name.endsWith('s') ? name : '${name}s'}';
  }

  /// Minutos desde las 00:00 → `9:00 a. m.` (la medianoche de cierre,
  /// `12:00 a. m.`).
  static String clock(int minute) {
    final m = minute % AgendaHours.minutesPerDay;
    return formatClock(m ~/ 60, m % 60);
  }

  /// `de 9:00 a. m. a 1:00 p. m. y de 3:00 p. m. a 7:00 p. m.`
  static String spans(List<MinuteSpan> spans) {
    final parts = [
      for (final s in spans) 'de ${clock(s.start)} a ${clock(s.end)}',
    ];
    if (parts.length <= 1) return parts.join();
    return '${parts.sublist(0, parts.length - 1).join(', ')} y ${parts.last}';
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// `Hoy`, `Mañana` o `El lunes`, respecto de [today].
  static String dayLabel(DateTime day, DateTime today) {
    if (_sameDay(day, today)) return 'Hoy';
    if (_sameDay(day, DateTime(today.year, today.month, today.day + 1))) {
      return 'Mañana';
    }
    return 'El ${weekday(day)}';
  }

  /// Título del aviso de un día cerrado (o en que el profesional del filtro
  /// no trabaja).
  static String closedDayTitle(AgendaDay day, DateTime today, {String? who}) {
    final isToday = _sameDay(day.day, today);
    if (day.isClosed) {
      final subject = day.source == AgendaHoursSource.team
          ? 'no trabaja nadie del equipo'
          : 'el negocio está cerrado';
      return isToday
          ? 'Hoy $subject'
          : '${_capital(weekdayPlural(day.day))} $subject';
    }
    // El negocio atiende, pero el profesional elegido no trabaja.
    if (who == null || who.isEmpty) {
      return isToday
          ? 'Hoy no trabajas'
          : 'No trabajas ${weekdayPlural(day.day)}';
    }
    return isToday
        ? 'Hoy $who no trabaja'
        : '$who no trabaja ${weekdayPlural(day.day)}';
  }

  /// "Abre el lunes a las 9:00 a. m." (o "Vuelve…" para un profesional).
  /// `null` si no vuelve a abrir en una semana.
  static String? nextOpening(AgendaHours hours, AgendaDay day, DateTime today,
      {String? who}) {
    final forProfessional = !day.isClosed;
    final next = hours.nextOpening(day.day, forProfessional: forProfessional);
    if (next == null) return null;
    final (date, span) = next;
    final when =
        _sameDay(date, DateTime(today.year, today.month, today.day + 1))
            ? 'mañana'
            : 'el ${weekday(date)}';
    final verb = !forProfessional
        ? (day.source == AgendaHoursSource.team
            ? 'Se vuelve a atender'
            : 'Abre')
        : (who == null || who.isEmpty ? 'Vuelves' : 'Vuelve');
    return _sentence('$verb $when a las ${clock(span.start)}');
  }

  /// Explicación al tocar una hora que no se puede reservar.
  static String closedAt(
      AgendaHours hours, AgendaDay day, int minute, DateTime today,
      {String? who}) {
    final at = 'A las ${clock(minute)}';
    final label = dayLabel(day.day, today);
    if (day.isClosed) {
      final next = nextOpening(hours, day, today, who: who);
      return '${closedDayTitle(day, today, who: who)}.'
          '${next == null ? '' : ' $next'}';
    }
    if (!day.referenceOpenAt(minute)) {
      final subject = day.source == AgendaHoursSource.team
          ? 'no trabaja nadie del equipo'
          : 'el negocio está cerrado';
      final verb =
          day.source == AgendaHoursSource.team ? 'se atiende' : 'atiende';
      return _sentence(
          '$at $subject. $label $verb ${spans(day.referenceOpen)}');
    }
    // Abre, pero el profesional elegido no trabaja a esa hora.
    final self = who == null || who.isEmpty;
    if (day.professionalOff) {
      final next = nextOpening(hours, day, today, who: who);
      return '${closedDayTitle(day, today, who: who)}.'
          '${next == null ? '' : ' $next'}';
    }
    return _sentence(self
        ? '$at no trabajas. $label trabajas ${spans(day.open)}'
        : '$at $who no trabaja. $label trabaja ${spans(day.open)}');
  }

  /// "Hoy atiende de 9:00 a. m. a 8:00 p. m." (para el aviso de nadie
  /// libre); `null` sin límites.
  static String? openToday(AgendaDay day, DateTime today) {
    if (day.source == AgendaHoursSource.none || day.isClosed) return null;
    final verb =
        day.source == AgendaHoursSource.team ? 'se atiende' : 'atiende';
    return _sentence(
        '${dayLabel(day.day, today)} $verb ${spans(day.referenceOpen)}');
  }

  /// Cierra la frase con un punto, sin duplicarlo tras "a. m."/"p. m.".
  static String _sentence(String text) => text.endsWith('.') ? text : '$text.';

  static String _capital(String text) =>
      text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);
}
