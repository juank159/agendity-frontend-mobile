import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/features/reminders/domain/entities/reminder_rule.dart';
import 'package:login_signup/features/reminders/domain/failures/reminder_failures.dart';
import 'package:login_signup/features/reminders/domain/repositories/reminders_repository.dart';
import 'package:login_signup/features/reminders/domain/usecases/reminder_rules.dart';

class PreviewReminderParams {
  final ReminderKind kind;

  /// Vacía = la plantilla por defecto del tipo.
  final String template;

  const PreviewReminderParams({required this.kind, this.template = ''});
}

/// Texto de ejemplo de una plantilla (datos ficticios, nombre y zona del
/// negocio).
class PreviewReminderUseCase extends UseCase<String, PreviewReminderParams> {
  final RemindersRepository repository;

  PreviewReminderUseCase(this.repository);

  @override
  Future<Either<Failure, String>> call(PreviewReminderParams params) async {
    final problems =
        ReminderRules.templateProblems(params.template, allowEmpty: true);
    if (problems.isNotEmpty) {
      return Left(InvalidReminderDataFailure.of(problems));
    }
    return repository.preview(params.kind, params.template.trim());
  }
}
