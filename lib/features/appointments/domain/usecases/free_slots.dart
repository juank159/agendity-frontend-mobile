/// Una franja de un horario semanal (día ISO 1 = lunes … 7 = domingo) en
/// minutos desde las 00:00 del negocio.
class ScheduleWindow {
  final int dayOfWeek;
  final int startMinute;
  final int endMinute;

  const ScheduleWindow(this.dayOfWeek, this.startMinute, this.endMinute);

  /// `"09:00"` o `"09:00:00"`; `null` si no es una hora.
  static int? minutesOf(String time) {
    final parts = time.trim().split(':');
    if (parts.length < 2) return null;
    final hours = int.tryParse(parts[0]);
    final minutes = int.tryParse(parts[1]);
    if (hours == null || minutes == null) return null;
    return hours * 60 + minutes;
  }

  /// El horario de apertura **en la app** (D-26): cada día cuenta como un
  /// solo tramo, de la primera apertura al último cierre (el almuerzo del
  /// negocio no cierra la agenda de la app; solo el link público). Los días
  /// sin franjas siguen cerrados. Una franja por día, ordenadas por día.
  static List<ScheduleWindow> daySpans(List<ScheduleWindow> windows) {
    final spans = <int, ScheduleWindow>{};
    for (final w in windows) {
      if (w.endMinute <= w.startMinute) continue;
      final current = spans[w.dayOfWeek];
      spans[w.dayOfWeek] = current == null
          ? w
          : ScheduleWindow(
              w.dayOfWeek,
              w.startMinute < current.startMinute
                  ? w.startMinute
                  : current.startMinute,
              w.endMinute > current.endMinute
                  ? w.endMinute
                  : current.endMinute);
    }
    return [
      for (final day in spans.keys.toList()..sort()) spans[day]!,
    ];
  }
}

/// Un intervalo ocupado [start, end) en hora de pared del negocio.
class BusyInterval {
  final DateTime start;
  final DateTime end;

  const BusyInterval(this.start, this.end);
}

/// Horas libres calculadas **en la app** (10.02b, D-18), con las mismas
/// reglas que `freeSlotStarts` del backend (`appointment-slot.ts`), para
/// cuando no hay conexión. Con conexión manda el servidor, y al sincronizar
/// decide él (una cita sin hueco vuelve como conflicto para mover).
///
/// - Candidatos cada [stepMinutes] desde las 00:00 del día.
/// - El hueco [inicio, inicio + duración) debe caber entero en una franja
///   del día (las franjas que se tocan se unen) del horario del
///   **profesional** (sin franjas = sin restricción, todas sus franjas
///   valen, incluido su almuerzo) y en la apertura del **negocio** (`null` =
///   sin horario; lista vacía = cerrado). En la app la apertura de cada día
///   es un solo tramo, de la primera apertura al último cierre
///   ([ScheduleWindow.daySpans], D-26): el almuerzo del negocio solo cierra
///   el link público.
/// - No se cruza con nada ocupado (citas que no están canceladas ni para
///   mover, y bloqueos), intervalos semiabiertos.
/// - No se ofrecen horas ya pasadas ([now]).
///
/// Todo en hora de pared del negocio (`BusinessTimeZone`).
abstract final class FreeSlots {
  static List<DateTime> compute({
    required DateTime day,
    required int durationMinutes,
    int stepMinutes = 15,
    required List<ScheduleWindow> professionalWindows,
    List<ScheduleWindow>? businessWindows,
    List<BusyInterval> busy = const [],
    required DateTime now,
  }) {
    if (stepMinutes <= 0 || durationMinutes <= 0) return const [];
    final weekday = DateTime(day.year, day.month, day.day).weekday;
    final opening = businessWindows == null
        ? null
        : ScheduleWindow.daySpans(businessWindows);
    final starts = <DateTime>[];
    for (var minute = 0; minute < 24 * 60; minute += stepMinutes) {
      final start = DateTime(day.year, day.month, day.day, 0, minute);
      final end = DateTime(
          day.year, day.month, day.day, 0, minute + durationMinutes);
      final to = minute + durationMinutes;
      if (start.isBefore(now)) continue;
      if (professionalWindows.isNotEmpty &&
          !_fits(minute, to, weekday, professionalWindows)) {
        continue;
      }
      if (opening != null && !_fits(minute, to, weekday, opening)) {
        continue;
      }
      if (busy.any((b) => start.isBefore(b.end) && end.isAfter(b.start))) {
        continue;
      }
      starts.add(start);
    }
    return starts;
  }

  static bool _fits(
      int from, int to, int weekday, List<ScheduleWindow> windows) {
    final day = [
      for (final w in windows)
        if (w.dayOfWeek == weekday) [w.startMinute, w.endMinute],
    ]..sort((a, b) => a[0].compareTo(b[0]));
    final merged = <List<int>>[];
    for (final w in day) {
      if (merged.isNotEmpty && w[0] <= merged.last[1]) {
        merged.last[1] = w[1] > merged.last[1] ? w[1] : merged.last[1];
      } else {
        merged.add([w[0], w[1]]);
      }
    }
    return merged.any((w) => w[0] <= from && to <= w[1]);
  }
}
