import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/features/reminders/domain/entities/reminder_settings.dart';
import 'package:login_signup/features/reminders/domain/failures/reminder_failures.dart';
import 'package:login_signup/features/reminders/domain/repositories/reminders_repository.dart';
import 'package:login_signup/features/reminders/domain/usecases/reminder_rules.dart';

/// Enciende o apaga los recordatorios y cambia la ventana de envío.
class UpdateReminderSettingsUseCase
    extends UseCase<ReminderSettings, ReminderSettings> {
  static const invalidWindow =
      'La ventana de envío debe tener horas con el formato HH:mm';

  final RemindersRepository repository;

  UpdateReminderSettingsUseCase(this.repository);

  @override
  Future<Either<Failure, ReminderSettings>> call(
      ReminderSettings params) async {
    if (!ReminderRules.isTime(params.sendWindowStart) ||
        !ReminderRules.isTime(params.sendWindowEnd)) {
      return const Left(InvalidReminderDataFailure(message: invalidWindow));
    }
    return repository.updateSettings(params);
  }
}
