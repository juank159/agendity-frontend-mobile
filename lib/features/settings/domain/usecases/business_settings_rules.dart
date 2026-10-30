import 'package:login_signup/common/entities/work_hours.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/features/settings/domain/entities/opening_hours.dart';
import 'package:login_signup/features/settings/domain/failures/settings_failures.dart';

/// Reglas de la configuración del negocio que se comprueban antes de ir al
/// backend (`UpdateSettingsDto` + `openingHoursError`), más una que el
/// backend no mira: franjas del mismo día que se pisan.
abstract final class BusinessSettingsRules {
  static const minNameLength = 2;
  static const maxNameLength = 100;

  /// `ArrayMaxSize` del DTO.
  static const maxRanges = 28;

  static const dayNames = [
    'lunes',
    'martes',
    'miércoles',
    'jueves',
    'viernes',
    'sábado',
    'domingo',
  ];

  /// `null` si [name] (ya recortado) es válido.
  static Failure? checkName(String name) =>
      name.length < minNameLength || name.length > maxNameLength
          ? const InvalidBusinessNameFailure()
          : null;

  /// Horas recortadas y `"09:00:00"` → `"09:00"`.
  static OpeningHours normalize(OpeningHours hours) => OpeningHours([
        for (final range in hours.ranges)
          OpeningHoursRange(
            dayOfWeek: range.dayOfWeek,
            hours: WorkHours(
              start: WorkHours.normalize(range.start),
              end: WorkHours.normalize(range.end),
            ),
          ),
      ]);

  /// `null` si el horario (ya normalizado) es coherente; si no, el primer
  /// problema con un mensaje que lo nombra.
  static Failure? checkOpeningHours(OpeningHours hours) {
    if (hours.ranges.length > maxRanges) {
      return const InvalidOpeningHoursFailure(
          message: 'Demasiadas franjas en el horario (máximo $maxRanges)');
    }
    for (final range in hours.ranges) {
      if (range.dayOfWeek < OpeningHoursRange.monday ||
          range.dayOfWeek > OpeningHoursRange.sunday) {
        return const InvalidOpeningHoursFailure(
            message: 'El día de la semana debe ser de lunes a domingo');
      }
      final day = dayNames[range.dayOfWeek - 1];
      if (!WorkHours.isValidTime(range.start) ||
          !WorkHours.isValidTime(range.end)) {
        return InvalidOpeningHoursFailure(
            message: 'Las horas del $day deben tener el formato HH:mm');
      }
      if (range.end.compareTo(range.start) <= 0) {
        return InvalidOpeningHoursFailure(
            message: 'El $day la hora de cierre (${range.end}) debe ser '
                'posterior a la de apertura (${range.start})');
      }
    }
    final ranges = hours.ranges; // ordenadas por día y apertura
    for (var i = 1; i < ranges.length; i++) {
      if (ranges[i].overlaps(ranges[i - 1])) {
        final day = dayNames[ranges[i].dayOfWeek - 1];
        return InvalidOpeningHoursFailure(
            message: 'El $day las franjas ${ranges[i - 1].hours} y '
                '${ranges[i].hours} se pisan');
      }
    }
    return null;
  }
}
