import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/features/reminders/domain/entities/reminder_rule.dart';
import 'package:login_signup/features/reminders/domain/repositories/reminders_repository.dart';

/// Reglas del negocio.
class GetReminderRulesUseCase extends UseCase<List<ReminderRule>, NoParams> {
  final RemindersRepository repository;

  GetReminderRulesUseCase(this.repository);

  @override
  Future<Either<Failure, List<ReminderRule>>> call(NoParams params) =>
      repository.getRules();
}
