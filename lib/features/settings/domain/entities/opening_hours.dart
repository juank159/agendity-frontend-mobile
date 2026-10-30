import 'package:login_signup/common/entities/work_hours.dart';
import 'package:login_signup/core/utils/deep_equality.dart';

/// Franja del horario de apertura del negocio (8.01): un día de la semana
/// (ISO: 1 = lunes … 7 = domingo) y su apertura y cierre en hora del negocio
/// (`HH:mm`). Un día puede tener varias franjas (cerrar a mediodía).
class OpeningHoursRange {
  static const monday = 1;
  static const sunday = 7;

  final int dayOfWeek;
  final WorkHours hours;

  const OpeningHoursRange({required this.dayOfWeek, required this.hours});

  String get start => hours.start;
  String get end => hours.end;

  /// Se pisa con [other] (mismo día y [inicio, fin) cruzados). Una franja que
  /// empieza justo cuando la otra cierra no se pisa.
  bool overlaps(OpeningHoursRange other) =>
      dayOfWeek == other.dayOfWeek &&
      start.compareTo(other.end) < 0 &&
      other.start.compareTo(end) < 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OpeningHoursRange &&
          other.dayOfWeek == dayOfWeek &&
          other.hours == hours;

  @override
  int get hashCode => Object.hash(dayOfWeek, hours);

  @override
  String toString() => '$dayOfWeek $hours';
}

/// Horario de apertura del negocio. Un día sin franjas está **cerrado**.
/// "Sin horario configurado" (no limita las citas) no es un `OpeningHours`
/// vacío sino `BusinessSettings.openingHours == null`.
class OpeningHours {
  /// Ordenadas por día y apertura (como las guarda el backend).
  final List<OpeningHoursRange> ranges;

  OpeningHours(Iterable<OpeningHoursRange> ranges)
      : ranges = List.unmodifiable(ranges.toList()
          ..sort((a, b) => a.dayOfWeek != b.dayOfWeek
              ? a.dayOfWeek.compareTo(b.dayOfWeek)
              : a.start.compareTo(b.start)));

  /// Cerrado todos los días.
  static final closed = OpeningHours(const []);

  List<OpeningHoursRange> rangesOn(int dayOfWeek) => [
        for (final range in ranges)
          if (range.dayOfWeek == dayOfWeek) range
      ];

  bool isClosedOn(int dayOfWeek) => rangesOn(dayOfWeek).isEmpty;

  /// Las franjas de [dayOfWeek] sustituidas por [hours] (vacío = cerrado).
  OpeningHours withDay(int dayOfWeek, Iterable<WorkHours> hours) =>
      OpeningHours([
        for (final range in ranges)
          if (range.dayOfWeek != dayOfWeek) range,
        for (final h in hours)
          OpeningHoursRange(dayOfWeek: dayOfWeek, hours: h),
      ]);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OpeningHours && DeepEquality.lists(other.ranges, ranges);

  @override
  int get hashCode => Object.hashAll(ranges);

  @override
  String toString() => 'OpeningHours($ranges)';
}
