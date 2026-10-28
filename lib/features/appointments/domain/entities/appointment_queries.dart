import 'package:login_signup/core/utils/business_time_zone.dart';
import 'package:login_signup/core/utils/deep_equality.dart';

/// Rango de citas a leer: [start] incluido, [end] excluido. Horas de pared
/// del negocio (D-15) o instantes en UTC.
class AppointmentsRange {
  final DateTime start;
  final DateTime end;

  const AppointmentsRange({required this.start, required this.end});

  /// El día [day] completo del calendario del negocio.
  factory AppointmentsRange.day(DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    return AppointmentsRange(
        start: start, end: DateTime(day.year, day.month, day.day + 1));
  }

  bool get isInverted => end.isBefore(start);

  /// [moment] dentro del rango, comparando instantes (una hora de pared se
  /// toma en la zona del negocio; para una cita, `startInstant`).
  bool contains(DateTime moment) {
    final instant = BusinessTimeZone.toInstant(moment);
    return !instant.isBefore(BusinessTimeZone.toInstant(start)) &&
        instant.isBefore(BusinessTimeZone.toInstant(end));
  }

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
