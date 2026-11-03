import 'package:login_signup/common/entities/work_hours.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/features/appointments/domain/entities/appointment_entity.dart';
import 'package:login_signup/features/appointments/domain/failures/appointment_failures.dart';
import 'package:login_signup/features/appointments/domain/usecases/agenda_hours.dart';
import 'package:login_signup/features/appointments/domain/usecases/free_slots.dart';
import 'package:login_signup/features/appointments/presentation/widgets/agenda_hours_text.dart';

/// Textos de una cita guardada con conflicto al sincronizar
/// (`needsReschedule`, 10.03).
extension AppointmentConflictUi on AppointmentEntity {
  /// Por qué hay que moverla, en lenguaje humano.
  String get rescheduleReason => switch (syncConflict) {
        'OUTSIDE_BUSINESS_HOURS' =>
          'El negocio estaba cerrado a esa hora cuando se sincronizó: '
              'muévela a otra hora.',
        'PROFESSIONAL_INACTIVE' =>
          'El profesional no estaba disponible cuando se sincronizó: muévela '
              'o cámbiale el profesional.',
        'SERVICE_NOT_OFFERED_BY_PROFESSIONAL' ||
        'SERVICE_INACTIVE' =>
          'Uno de los servicios ya no se puede agendar con este profesional: '
              'cámbialo o muévela.',
        _ => 'Esta hora ya estaba ocupada cuando se sincronizó: muévela a otra '
            'hora.',
      };
}

/// Por qué no se pudo agendar o mover a esa hora (13.05), en palabras
/// simples y con las horas en 12 h (D-23). El failure trae los datos
/// (`reason`, `hours`, 13.04) y aquí se arma el texto: el dominio no lleva
/// textos de UI.
abstract final class SlotProblemText {
  /// Sujeto cuando no se sabe el nombre del profesional.
  static const unnamedProfessional = 'La profesional';

  /// El texto del motivo, o `null` si [failure] no trae uno conocido (el
  /// llamador usa entonces `failure.message`). [professionalName] = nombre
  /// del profesional elegido en el formulario.
  static String? of(Failure failure, {String? professionalName}) {
    final name = (professionalName?.trim().isNotEmpty ?? false)
        ? professionalName!.trim()
        : unnamedProfessional;
    return switch (failure) {
      SlotUnavailableFailure(
        reason: SlotUnavailableReason.professionalOffSchedule,
        :final hours
      ) =>
        hours.isEmpty
            ? '$name no trabaja ese día'
            : '$name no trabaja a esa hora (atiende ${_spans(hours)})',
      SlotUnavailableFailure(reason: SlotUnavailableReason.timeBlock) =>
        'Ese horario está bloqueado',
      SlotUnavailableFailure(
        reason: SlotUnavailableReason.appointmentOverlap
      ) =>
        'Ya hay una cita a esa hora',
      OutsideBusinessHoursFailure(
        reason: OutsideBusinessHoursReason.businessClosedDay
      ) =>
        'El negocio está cerrado ese día',
      OutsideBusinessHoursFailure(
        reason: OutsideBusinessHoursReason.outsideOpeningHours,
        :final hours
      ) =>
        hours.isEmpty
            ? 'El negocio está cerrado a esa hora'
            : 'El negocio atiende ${_spans(hours)}',
      _ => null,
    };
  }

  /// `de 9:00 a. m. a 1:00 p. m. y de 2:00 p. m. a 6:00 p. m.`
  static String _spans(List<WorkHours> hours) => AgendaHoursText.spans([
        for (final h in hours)
          if (AgendaHours.window(1, h) case final ScheduleWindow w)
            MinuteSpan(w.startMinute, w.endMinute),
      ]);
}
