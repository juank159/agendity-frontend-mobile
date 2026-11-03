import 'package:login_signup/common/entities/work_hours.dart';
import 'package:login_signup/features/appointments/domain/usecases/free_slots.dart';

/// Intervalo [start, end) en minutos desde las 00:00 de un día del negocio.
class MinuteSpan {
  final int start;
  final int end;

  const MinuteSpan(this.start, this.end);

  static const wholeDay = MinuteSpan(0, AgendaHours.minutesPerDay);

  bool contains(int minute) => start <= minute && minute < end;

  @override
  bool operator ==(Object other) =>
      other is MinuteSpan && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => 'MinuteSpan($start-$end)';
}

/// De dónde sale el horario que limita la agenda (D-25).
enum AgendaHoursSource {
  /// El horario de apertura del negocio (`BusinessSettings.openingHours`).
  business,

  /// Sin apertura configurada: la unión de los horarios de los profesionales
  /// activos (todos tienen horario).
  team,

  /// Sin límites: ni apertura ni horario de todo el equipo.
  none,
}

/// Lo que la agenda muestra y deja reservar un día (D-25), en hora de pared
/// del negocio.
class AgendaDay {
  /// Día (solo cuentan año, mes y día).
  final DateTime day;
  final AgendaHoursSource source;

  /// Franjas en que el negocio (o el equipo) atiende ese día, unidas y
  /// ordenadas. Vacía = cerrado. Sin límites, todo el día. Con la apertura
  /// del negocio es un solo tramo, de la primera apertura al último cierre
  /// (D-26).
  final List<MinuteSpan> referenceOpen;

  /// Lo que se puede reservar: [referenceOpen] y, con un profesional
  /// elegido (filtro o la empleada), solo cuando él trabaja.
  final List<MinuteSpan> open;

  /// Hay un profesional elegido con horario propio.
  final bool limitedByProfessional;

  /// Primera hora visible (0–23) y hora en que termina la vista (1–24).
  final int startHour;
  final int endHour;

  const AgendaDay({
    required this.day,
    required this.source,
    required this.referenceOpen,
    required this.open,
    required this.limitedByProfessional,
    required this.startHour,
    required this.endHour,
  });

  /// Algo limita las horas (si no, no hay nada que sombrear).
  bool get isLimited =>
      source != AgendaHoursSource.none || limitedByProfessional;

  /// El negocio (o todo el equipo) no atiende este día.
  bool get isClosed => referenceOpen.isEmpty;

  /// El negocio atiende, pero el profesional elegido no trabaja este día.
  bool get professionalOff => !isClosed && open.isEmpty;

  /// Se puede reservar a partir de [minute] (minutos desde las 00:00).
  bool isOpenAt(int minute) => open.any((s) => s.contains(minute));

  /// El negocio (o el equipo) atiende a [minute], sin mirar al profesional.
  bool referenceOpenAt(int minute) =>
      referenceOpen.any((s) => s.contains(minute));

  /// Lo no reservable dentro de [from, to) (minutos): lo que se sombrea.
  List<MinuteSpan> closedWithin(int from, int to) {
    if (!isLimited || to <= from) return const [];
    final result = <MinuteSpan>[];
    var cursor = from;
    for (final span in open) {
      if (span.end <= cursor) continue;
      if (span.start >= to) break;
      if (span.start > cursor) result.add(MinuteSpan(cursor, span.start));
      if (span.end > cursor) cursor = span.end;
    }
    if (cursor < to) result.add(MinuteSpan(cursor, to));
    return result;
  }

  /// Lo no reservable dentro de la vista del día.
  List<MinuteSpan> get closed => closedWithin(startHour * 60, endHour * 60);

  @override
  String toString() =>
      'AgendaDay($day, $source, $startHour-$endHour, open: $open)';
}

/// La semana (o los días visibles): un rango común y los días.
class AgendaWeek {
  final List<AgendaDay> days;
  final int startHour;
  final int endHour;

  const AgendaWeek(
      {required this.days, required this.startHour, required this.endHour});

  /// Lo no reservable de [day] dentro del rango común de la semana.
  List<MinuteSpan> closedOf(AgendaDay day) =>
      day.closedWithin(startHour * 60, endHour * 60);
}

/// Rango de horas y zonas no reservables de la agenda (D-25). Función pura
/// (sin Flutter), en hora de pared del negocio:
///
/// - **Rango de un día:** desde la hora completa de la primera apertura
///   (`floor`) hasta la hora completa del último cierre (`ceil`).
///   - Fuente: el horario de apertura ([business], `null` = sin
///     configurar); si no hay, la unión de los horarios del equipo activo
///     ([team]) cuando **todos** tienen horario (uno sin horario atiende a
///     cualquier hora); si tampoco, sin límites y el rango por defecto
///     ([defaultStartHour]–[defaultEndHour]).
///   - Un día cerrado usa el rango de toda la semana (todo sombreado).
///   - Si ese día hay citas fuera del rango, el rango se amplía: nunca se
///     esconde una cita.
/// - **Lo reservable:** lo que atiende el negocio y, con un profesional
///   elegido ([professional], filtro o la empleada), solo cuando trabaja
///   (con todas sus franjas: su almuerzo se sombrea).
/// - **D-26:** la apertura del negocio cuenta en la app como un solo tramo
///   por día, de la primera apertura al último cierre: el almuerzo del
///   negocio no se sombrea ni bloquea el toque (solo cierra el link
///   público). Sin apertura, el horario del equipo sí conserva sus huecos
///   (en ellos no trabaja nadie).
/// - **Semana:** el rango es la unión de los rangos de sus días.
class AgendaHours {
  static const minutesPerDay = 24 * 60;
  static const defaultStartHour = 6;
  static const defaultEndHour = 24;

  /// Horario de apertura; `null` = sin configurar. Vacío = cerrado siempre.
  final List<ScheduleWindow>? business;

  /// Horario semanal de cada profesional activo (lista vacía = sin horario,
  /// atiende a cualquier hora).
  final List<List<ScheduleWindow>> team;

  /// Horario del profesional elegido; `null` o vacío = sin filtro.
  final List<ScheduleWindow>? professional;

  const AgendaHours({this.business, this.team = const [], this.professional});

  /// Sin ningún límite (rango por defecto, nada sombreado).
  static const unlimited = AgendaHours();

  /// La misma agenda con otro profesional elegido (`null` = ninguno).
  AgendaHours withProfessional(List<ScheduleWindow>? windows) =>
      AgendaHours(business: business, team: team, professional: windows);

  AgendaHoursSource get source {
    if (business != null) return AgendaHoursSource.business;
    if (team.isNotEmpty && team.every((s) => s.isNotEmpty)) {
      return AgendaHoursSource.team;
    }
    return AgendaHoursSource.none;
  }

  /// Horario semanal que manda, o `null` sin límites.
  List<ScheduleWindow>? get _reference => switch (source) {
        // D-26: en la app el día del negocio va de corrido (el almuerzo
        // solo cierra el link público).
        AgendaHoursSource.business => ScheduleWindow.daySpans(business!),
        AgendaHoursSource.team => [for (final s in team) ...s],
        AgendaHoursSource.none => null,
      };

  List<ScheduleWindow>? get _professional {
    final windows = professional;
    return windows == null || windows.isEmpty ? null : windows;
  }

  /// El día [day]; [appointments] = inicio y fin (hora de pared) de las
  /// citas visibles (las de otros días no cuentan).
  AgendaDay day(DateTime day,
      {Iterable<(DateTime, DateTime)> appointments = const []}) {
    final date = DateTime(day.year, day.month, day.day);
    final weekday = date.weekday;
    final reference = _reference;
    final pro = _professional;
    final referenceOpen = reference == null
        ? const [MinuteSpan.wholeDay]
        : _on(reference, weekday);
    final open = pro == null
        ? referenceOpen
        : _intersect(referenceOpen, _on(pro, weekday));

    // Lo que marca el rango: el horario del negocio o del equipo; sin él, el
    // del profesional elegido.
    List<MinuteSpan> base;
    if (reference != null) {
      base = referenceOpen.isNotEmpty ? referenceOpen : _anyDay(reference);
    } else if (pro != null) {
      base = open.isNotEmpty ? open : _anyDay(pro);
    } else {
      base = const [];
    }
    var start = defaultStartHour;
    var end = defaultEndHour;
    if (base.isNotEmpty) {
      start = base.first.start ~/ 60;
      end = _ceilHour(base.last.end);
    }
    for (final span in _appointmentSpans(date, appointments)) {
      if (span.start ~/ 60 < start) start = span.start ~/ 60;
      if (_ceilHour(span.end) > end) end = _ceilHour(span.end);
    }
    start = start.clamp(0, 23);
    end = end.clamp(start + 1, 24);

    return AgendaDay(
      day: date,
      source: source,
      referenceOpen: referenceOpen,
      open: open,
      limitedByProfessional: pro != null,
      startHour: start,
      endHour: end,
    );
  }

  /// Los días [days] con un rango común (la unión de los de cada día).
  AgendaWeek week(Iterable<DateTime> days,
      {Iterable<(DateTime, DateTime)> appointments = const []}) {
    final list = [
      for (final d in days) day(d, appointments: appointments),
    ];
    if (list.isEmpty) {
      return const AgendaWeek(
          days: [], startHour: defaultStartHour, endHour: defaultEndHour);
    }
    var start = list.first.startHour;
    var end = list.first.endHour;
    for (final d in list) {
      if (d.startHour < start) start = d.startHour;
      if (d.endHour > end) end = d.endHour;
    }
    return AgendaWeek(days: list, startHour: start, endHour: end);
  }

  /// Próxima apertura después de [day] (hasta una semana): el día y la
  /// franja. Con [forProfessional], la próxima vez que trabaja el
  /// profesional elegido. `null` si no hay ninguna.
  (DateTime, MinuteSpan)? nextOpening(DateTime day,
      {bool forProfessional = false}) {
    for (var i = 1; i <= 7; i++) {
      final next = this.day(DateTime(day.year, day.month, day.day + i));
      final spans = forProfessional ? next.open : next.referenceOpen;
      if (spans.isNotEmpty) return (next.day, spans.first);
    }
    return null;
  }

  // --- Conversión desde las entidades ------------------------------------

  /// Una franja `HH:mm` de [dayOfWeek] (ISO); `null` si no es válida.
  static ScheduleWindow? window(int dayOfWeek, WorkHours hours) {
    final start = ScheduleWindow.minutesOf(hours.start);
    final end = ScheduleWindow.minutesOf(hours.end);
    if (start == null || end == null || end <= start) return null;
    return ScheduleWindow(dayOfWeek, start, end);
  }

  /// Horario semanal de un profesional (claves `WorkHours.weekdays`), con
  /// todas las franjas de cada día (13.05).
  static List<ScheduleWindow> weekly(Map<String, List<WorkHours>> schedule) =>
      [
        for (final entry in schedule.entries)
          if (WorkHours.weekdays.indexOf(entry.key) case final i when i >= 0)
            for (final hours in entry.value)
              if (window(i + 1, hours) case final w?) w,
      ];

  // --- Cuentas -----------------------------------------------------------

  static int _ceilHour(int minute) => (minute + 59) ~/ 60;

  /// Franjas de [weekday], unidas y ordenadas.
  static List<MinuteSpan> _on(List<ScheduleWindow> windows, int weekday) =>
      _merge([
        for (final w in windows)
          if (w.dayOfWeek == weekday) MinuteSpan(w.startMinute, w.endMinute),
      ]);

  /// Todas las franjas de la semana como si fueran de un día (rango de un
  /// día cerrado).
  static List<MinuteSpan> _anyDay(List<ScheduleWindow> windows) => _merge([
        for (final w in windows) MinuteSpan(w.startMinute, w.endMinute),
      ]);

  static List<MinuteSpan> _merge(List<MinuteSpan> spans) {
    final sorted = [
      for (final s in spans)
        if (s.end > s.start)
          MinuteSpan(
              s.start.clamp(0, minutesPerDay), s.end.clamp(0, minutesPerDay)),
    ]..sort((a, b) => a.start.compareTo(b.start));
    final merged = <MinuteSpan>[];
    for (final s in sorted) {
      if (merged.isNotEmpty && s.start <= merged.last.end) {
        final last = merged.removeLast();
        merged.add(MinuteSpan(last.start, s.end > last.end ? s.end : last.end));
      } else {
        merged.add(s);
      }
    }
    return merged;
  }

  static List<MinuteSpan> _intersect(List<MinuteSpan> a, List<MinuteSpan> b) {
    final result = <MinuteSpan>[];
    var i = 0;
    var j = 0;
    while (i < a.length && j < b.length) {
      final start = a[i].start > b[j].start ? a[i].start : b[j].start;
      final end = a[i].end < b[j].end ? a[i].end : b[j].end;
      if (start < end) result.add(MinuteSpan(start, end));
      if (a[i].end < b[j].end) {
        i++;
      } else {
        j++;
      }
    }
    return result;
  }

  /// La parte de cada cita que cae en [date], en minutos.
  static Iterable<MinuteSpan> _appointmentSpans(
      DateTime date, Iterable<(DateTime, DateTime)> appointments) sync* {
    final next = DateTime(date.year, date.month, date.day + 1);
    for (final (start, end) in appointments) {
      if (!start.isBefore(next) || !end.isAfter(date)) {
        // Una cita sin duración también cuenta si empieza ese día.
        if (!(start == end && !start.isBefore(date) && start.isBefore(next))) {
          continue;
        }
      }
      final from = start.isBefore(date) ? 0 : start.hour * 60 + start.minute;
      final to =
          end.isBefore(next) ? end.hour * 60 + end.minute : minutesPerDay;
      yield MinuteSpan(from, to > from ? to : from + 1);
    }
  }
}
