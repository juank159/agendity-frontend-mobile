import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/features/appointments/domain/entities/appointment_changes.dart';
import 'package:login_signup/features/appointments/domain/entities/appointment_entity.dart';
import 'package:login_signup/features/appointments/domain/repositories/appointments_repository.dart';
import 'package:login_signup/features/appointments/domain/usecases/appointment_rules.dart';

class UpdateAppointmentParams {
  /// La cita tal como la vio el usuario al abrir el formulario.
  final AppointmentEntity original;

  /// Solo lo que cambió (`AppointmentChanges.between`).
  final AppointmentChanges changes;

  const UpdateAppointmentParams({required this.original, required this.changes});
}

/// Edita (o mueve) una cita enviando solo lo que cambió. Sin cambios no llama
/// al backend y devuelve la original. No consulta el cupo del plan: editar no
/// consume citas.
class UpdateAppointmentUseCase
    extends UseCase<AppointmentEntity, UpdateAppointmentParams> {
  final AppointmentsRepository repository;
  final DateTime Function() _now;

  UpdateAppointmentUseCase(this.repository, {DateTime Function()? now})
      : _now = now ?? DateTime.now;

  @override
  Future<Either<Failure, AppointmentEntity>> call(
      UpdateAppointmentParams params) async {
    final changes = params.changes;
    if (changes.isEmpty) return Right(params.original);

    final serviceIds = changes.serviceIds;
    final invalid = (serviceIds == null
            ? null
            : AppointmentRules.checkServices(serviceIds)) ??
        (changes.start == null
            ? null
            : AppointmentRules.checkStart(changes.start!, _now()));
    if (invalid != null) return Left(invalid);

    return repository.updateAppointment(params.original.id, changes);
  }
}
