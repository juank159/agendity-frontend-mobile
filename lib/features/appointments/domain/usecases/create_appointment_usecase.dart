import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/core/utils/business_time_zone.dart';
import 'package:login_signup/features/appointments/domain/entities/appointment_entity.dart';
import 'package:login_signup/features/appointments/domain/entities/new_appointment.dart';
import 'package:login_signup/features/appointments/domain/repositories/appointments_repository.dart';
import 'package:login_signup/features/appointments/domain/usecases/appointment_rules.dart';

/// Agenda una cita. Comprueba antes lo que no necesita al servidor (servicios,
/// cliente, profesional y que sea a futuro); la disponibilidad, el profesional
/// activo y el cupo del plan los decide el backend.
class CreateAppointmentUseCase
    extends UseCase<AppointmentEntity, NewAppointment> {
  final AppointmentsRepository repository;
  final DateTime Function() _now;

  CreateAppointmentUseCase(this.repository, {DateTime Function()? now})
      : _now = now ?? BusinessTimeZone.now;

  @override
  Future<Either<Failure, AppointmentEntity>> call(
      NewAppointment params) async {
    final invalid = AppointmentRules.checkNew(params, _now());
    if (invalid != null) return Left(invalid);
    final notes = params.notes?.trim();
    return repository.createAppointment(NewAppointment(
      clientId: params.clientId.trim(),
      professionalId: params.professionalId.trim(),
      serviceIds: params.serviceIds,
      start: params.start,
      notes: notes == null || notes.isEmpty ? null : notes,
    ));
  }
}
