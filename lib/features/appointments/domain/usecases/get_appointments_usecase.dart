import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/features/appointments/domain/entities/appointment_entity.dart';
import 'package:login_signup/features/appointments/domain/entities/appointment_queries.dart';
import 'package:login_signup/features/appointments/domain/failures/appointment_failures.dart';
import 'package:login_signup/features/appointments/domain/repositories/appointments_repository.dart';

/// Citas de un rango (agenda por día, semana o mes).
class GetAppointmentsUseCase
    extends UseCase<List<AppointmentEntity>, AppointmentsRange> {
  static const invertedRangeMessage =
      'La fecha final no puede ser anterior a la inicial';

  final AppointmentsRepository repository;

  GetAppointmentsUseCase(this.repository);

  @override
  Future<Either<Failure, List<AppointmentEntity>>> call(
      AppointmentsRange params) async {
    if (params.isInverted) {
      return const Left(
          InvalidAppointmentDataFailure(message: invertedRangeMessage));
    }
    return repository.getAppointments(params);
  }
}
