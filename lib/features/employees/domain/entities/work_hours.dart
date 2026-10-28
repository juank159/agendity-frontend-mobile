/// Horario de un día de trabajo, en hora del negocio con formato `HH:mm`.
///
/// El horario semanal de un profesional es un `Map<String, WorkHours>` cuyas
/// claves son los días de [weekdays] (los que usa el backend). Un día sin
/// entrada es un día libre; un profesional sin ningún día no tiene
/// restricción de horario al agendar (regla del backend, 2.04).
class WorkHours {
  /// Días de la semana en el orden del backend (`day_of_week` 1 = lunes).
  static const weekdays = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
  ];

  static final _hhmm = RegExp(r'^([01]\d|2[0-3]):[0-5]\d$');

  final String start;
  final String end;

  const WorkHours({required this.start, required this.end});

  /// `"09:00"` y `"09:00:00"` (columna `time` de Postgres) → `"09:00"`.
  /// Cualquier otra cosa se devuelve recortada, sin inventar una hora.
  static String normalize(String value) {
    final trimmed = value.trim();
    final parts = trimmed.split(':');
    if (parts.length == 3 && _hhmm.hasMatch('${parts[0]}:${parts[1]}')) {
      return '${parts[0]}:${parts[1]}';
    }
    return trimmed;
  }

  /// `HH:mm` válido (00:00–23:59).
  static bool isValidTime(String value) => _hhmm.hasMatch(value);

  /// Ambas horas válidas y el fin después del inicio.
  bool get isValid =>
      isValidTime(start) && isValidTime(end) && start.compareTo(end) < 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkHours && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => '$start-$end';
}
