import 'package:login_signup/features/appointments/domain/entities/appointment_entity.dart';

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
