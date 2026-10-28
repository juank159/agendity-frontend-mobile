import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/features/appointments/domain/entities/appointment_queries.dart';
import 'package:login_signup/features/appointments/domain/failures/appointment_failures.dart';
import 'package:login_signup/features/appointments/domain/repositories/appointments_repository.dart';
import 'package:login_signup/features/appointments/domain/usecases/appointment_rules.dart';

/// Horas en las que se puede agendar (lo listado es lo que `POST
/// /appointments` acepta). Employee: solo su agenda.
class GetAvailableSlotsUseCase
    extends UseCase<List<DateTime>, AvailableSlotsQuery> {
  static const invalidStepMessage =
      'La separación entre horas debe estar entre 5 y 240 minutos';

  final AppointmentsRepository repository;

  GetAvailableSlotsUseCase(this.repository);

  @override
  Future<Either<Failure, List<DateTime>>> call(
      AvailableSlotsQuery params) async {
    if (params.professionalId.trim().isEmpty) {
      return const Left(InvalidAppointmentDataFailure(
          message: AppointmentRules.noProfessionalMessage));
    }
    final invalidServices = AppointmentRules.checkServices(params.serviceIds);
    if (invalidServices != null) return Left(invalidServices);
    final step = params.stepMinutes;
    if (step != null &&
        (step < AvailableSlotsQuery.minStepMinutes ||
            step > AvailableSlotsQuery.maxStepMinutes)) {
      return const Left(
          InvalidAppointmentDataFailure(message: invalidStepMessage));
    }
    return repository.getAvailableSlots(params);
  }
}
