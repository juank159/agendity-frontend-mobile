import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/features/appointments/domain/entities/appointment_entity.dart';
import 'package:login_signup/features/appointments/domain/repositories/appointments_repository.dart';

/// Una cita por id: para refrescarla tras un cambio hecho por otra feature
/// (p. ej. un pago, que cambia `paymentStatus` y confirma la cita).
class GetAppointmentUseCase extends UseCase<AppointmentEntity, String> {
  final AppointmentsRepository repository;

  GetAppointmentUseCase(this.repository);

  @override
  Future<Either<Failure, AppointmentEntity>> call(String params) =>
      repository.getAppointment(params);
}
