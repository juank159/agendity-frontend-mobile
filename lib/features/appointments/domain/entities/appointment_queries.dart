import 'package:login_signup/core/utils/deep_equality.dart';

/// Rango de citas a leer: [start] incluido, [end] excluido (instantes).
class AppointmentsRange {
  final DateTime start;
  final DateTime end;

  const AppointmentsRange({required this.start, required this.end});

  /// El día local de [day] completo.
  factory AppointmentsRange.day(DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    return AppointmentsRange(
        start: start, end: DateTime(day.year, day.month, day.day + 1));
  }

  bool get isInverted => end.isBefore(start);

  bool contains(DateTime instant) =>
      !instant.isBefore(start) && instant.isBefore(end);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppointmentsRange && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => 'AppointmentsRange($start → $end)';
}

/// Consulta de horas libres (`GET /appointments/available-slots`).
class AvailableSlotsQuery {
  /// Separación entre inicios que acepta el backend (`SLOT_STEP_MINUTES`).
  static const minStepMinutes = 5;
  static const maxStepMinutes = 240;

  final String professionalId;

  /// Día del negocio (solo cuenta año, mes y día).
  final DateTime day;
  final List<String> serviceIds;

  /// `null` = el del backend (15 min).
  final int? stepMinutes;

  const AvailableSlotsQuery({
    required this.professionalId,
    required this.day,
    required this.serviceIds,
    this.stepMinutes,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AvailableSlotsQuery &&
          other.professionalId == professionalId &&
          other.day == day &&
          DeepEquality.lists(other.serviceIds, serviceIds) &&
          other.stepMinutes == stepMinutes;

  @override
  int get hashCode => Object.hash(
      professionalId, day, Object.hashAll(serviceIds), stepMinutes);
}
