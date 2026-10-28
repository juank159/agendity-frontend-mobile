/// Parámetros de toda consulta de estadísticas: al menos un rango.
abstract interface class StatsQuery {
  StatsRange get range;
}

/// Rango de días del negocio que piden las estadísticas, con los dos extremos
/// incluidos: el backend toma [start] desde las 00:00 y [end] hasta las
/// 23:59:59.999 en la zona horaria del negocio (D-15). Solo cuenta el día de
/// calendario de cada `DateTime` (la hora se ignora).
class StatsRange implements StatsQuery {
  final DateTime start;
  final DateTime end;

  const StatsRange({required this.start, required this.end});

  @override
  StatsRange get range => this;

  /// Un solo día (p. ej. "hoy").
  factory StatsRange.day(DateTime day) => StatsRange(start: day, end: day);

  /// `false` si el día de inicio es posterior al de fin.
  bool get isValid => !_day(start).isAfter(_day(end));

  static DateTime _day(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StatsRange &&
          _day(other.start) == _day(start) &&
          _day(other.end) == _day(end);

  @override
  int get hashCode => Object.hash(_day(start), _day(end));

  @override
  String toString() => 'StatsRange($start → $end)';
}
