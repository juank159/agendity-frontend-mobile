import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/features/appointments/domain/entities/appointment_entity.dart';
import 'package:login_signup/features/appointments/domain/failures/appointment_failures.dart';
import 'package:login_signup/features/appointments/domain/repositories/appointments_repository.dart';
import 'package:login_signup/features/appointments/domain/usecases/appointment_rules.dart';

class CancelAppointmentParams {
  final String appointmentId;

  /// Motivo opcional (máximo 500 caracteres).
  final String? reason;

  const CancelAppointmentParams({required this.appointmentId, this.reason});
}

/// Cancela una cita pendiente o confirmada. Con algo pagado el backend
/// responde `AppointmentPaidFailure` (hay que reembolsar antes). Cancelar no
/// devuelve el cupo del trial.
class CancelAppointmentUseCase
    extends UseCase<AppointmentEntity, CancelAppointmentParams> {
  static const reasonTooLongMessage =
      'El motivo de la cancelación admite como máximo 500 caracteres';

  final AppointmentsRepository repository;

  CancelAppointmentUseCase(this.repository);

  @override
  Future<Either<Failure, AppointmentEntity>> call(
      CancelAppointmentParams params) async {
    final reason = params.reason?.trim();
    if (reason != null &&
        reason.length > AppointmentRules.maxCancellationReasonLength) {
      return const Left(
          InvalidAppointmentDataFailure(message: reasonTooLongMessage));
    }
    return repository.cancelAppointment(params.appointmentId,
        reason: reason == null || reason.isEmpty ? null : reason);
  }
}
