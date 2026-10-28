import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/features/appointments/domain/entities/appointment_entity.dart';
import 'package:login_signup/features/appointments/domain/repositories/appointments_repository.dart';

/// Marca la cita como atendida (`PENDING|CONFIRMED → COMPLETED`). Se puede
/// completar sin pagar: el pago se registra después (2.15).
class CompleteAppointmentUseCase extends UseCase<AppointmentEntity, String> {
  final AppointmentsRepository repository;

  CompleteAppointmentUseCase(this.repository);

  @override
  Future<Either<Failure, AppointmentEntity>> call(String params) =>
      repository.completeAppointment(params);
}
