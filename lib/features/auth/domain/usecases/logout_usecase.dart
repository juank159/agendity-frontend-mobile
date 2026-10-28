import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/features/auth/domain/repositories/auth_repository.dart';

/// Único logout de datos (lo llama `LogoutController.endSession`).
class LogoutUseCase implements UseCase<Unit, NoParams> {
  final AuthRepository _repository;

  LogoutUseCase(this._repository);

  @override
  Future<Either<Failure, Unit>> call(NoParams params) => _repository.logout();
}
