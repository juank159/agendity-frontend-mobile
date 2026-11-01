import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/features/reminders/domain/entities/reminder_settings.dart';
import 'package:login_signup/features/reminders/domain/repositories/reminders_repository.dart';

/// Configuración de recordatorios, con el canal y el cupo del mes.
class GetReminderSettingsUseCase extends UseCase<ReminderSettings, NoParams> {
  final RemindersRepository repository;

  GetReminderSettingsUseCase(this.repository);

  @override
  Future<Either<Failure, ReminderSettings>> call(NoParams params) =>
      repository.getSettings();
}
