import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/features/appointments/domain/entities/appointment_entity.dart';
import 'package:login_signup/features/appointments/domain/repositories/appointments_repository.dart';

/// "Citas por mover" (10.03): las que se guardaron con conflicto al
/// sincronizar lo hecho sin conexión (la hora ya estaba ocupada, el negocio
/// estaba cerrado…). No ocupan hueco hasta moverlas.
class GetAppointmentsToRescheduleUseCase
    extends UseCase<List<AppointmentEntity>, NoParams> {
  final AppointmentsRepository repository;

  GetAppointmentsToRescheduleUseCase(this.repository);

  @override
  Future<Either<Failure, List<AppointmentEntity>>> call(NoParams params) =>
      repository.getAppointmentsToReschedule();
}
