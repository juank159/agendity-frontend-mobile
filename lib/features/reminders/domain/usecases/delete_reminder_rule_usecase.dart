import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/features/reminders/domain/repositories/reminders_repository.dart';

/// Borra una regla (el historial de sus envíos se conserva).
class DeleteReminderRuleUseCase extends UseCase<Unit, String> {
  final RemindersRepository repository;

  DeleteReminderRuleUseCase(this.repository);

  @override
  Future<Either<Failure, Unit>> call(String params) =>
      repository.deleteRule(params);
}
