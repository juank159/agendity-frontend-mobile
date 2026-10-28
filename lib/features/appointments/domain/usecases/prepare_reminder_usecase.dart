import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/features/appointments/domain/entities/manual_reminder.dart';
import 'package:login_signup/features/appointments/domain/repositories/appointments_repository.dart';

/// Pide al backend el recordatorio manual de una cita (teléfono del cliente
/// por la relación de la cita, texto y enlace `wa.me`). Cita que ya no está
/// pendiente ni confirmada, o cliente sin teléfono → `ReminderUnavailableFailure`.
class PrepareReminderUseCase extends UseCase<ManualReminder, String> {
  final AppointmentsRepository repository;

  PrepareReminderUseCase(this.repository);

  @override
  Future<Either<Failure, ManualReminder>> call(String params) =>
      repository.prepareReminder(params);
}
