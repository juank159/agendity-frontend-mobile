import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/features/reminders/domain/entities/reminder_rule.dart';
import 'package:login_signup/features/reminders/domain/failures/reminder_failures.dart';
import 'package:login_signup/features/reminders/domain/repositories/reminders_repository.dart';
import 'package:login_signup/features/reminders/domain/usecases/reminder_rules.dart';

/// Crea (sin id) o edita una regla, validada antes de enviarla. Plantilla
/// vacía = la del tipo (la pone el backend). El tipo no se puede cambiar.
class SaveReminderRuleUseCase extends UseCase<ReminderRule, ReminderRule> {
  final RemindersRepository repository;

  SaveReminderRuleUseCase(this.repository);

  @override
  Future<Either<Failure, ReminderRule>> call(ReminderRule params) async {
    final rule = params.copyWith(template: params.template.trim());
    final problems = ReminderRules.check(rule);
    if (problems.isNotEmpty) {
      return Left(InvalidReminderDataFailure.of(problems));
    }
    return repository.saveRule(rule);
  }
}
