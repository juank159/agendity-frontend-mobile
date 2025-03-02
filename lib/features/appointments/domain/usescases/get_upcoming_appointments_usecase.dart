// lib/features/appointments/domain/usecases/get_upcoming_appointments_usecase.dart

import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/features/appointments/domain/entities/appointment_entity.dart';

import '../../../../core/usecases/usecase.dart';

import '../repositories/appointments_repository.dart';

class GetUpcomingAppointmentsUseCase
    implements UseCase<List<AppointmentEntity>, NoParams> {
  final AppointmentsRepository repository;

  GetUpcomingAppointmentsUseCase(this.repository);

  @override
  Future<Either<Failure, List<AppointmentEntity>>> call(NoParams params) {
    return repository.getUpcomingAppointments();
  }
}
