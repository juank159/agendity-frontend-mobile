import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/features/appointments/domain/repositories/appointments_repository.dart';

/// Registra que el recordatorio manual se envió (tras abrir WhatsApp).
/// Devuelve la hora del primer envío.
class MarkReminderSentUseCase extends UseCase<DateTime, String> {
  final AppointmentsRepository repository;

  MarkReminderSentUseCase(this.repository);

  @override
  Future<Either<Failure, DateTime>> call(String params) =>
      repository.markReminderSent(params);
}
