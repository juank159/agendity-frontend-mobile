import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/features/auth/domain/repositories/auth_repository.dart';
import 'package:login_signup/features/auth/domain/usecases/auth_rules.dart';

/// Envía el código de recuperación de contraseña (email desconocido →
/// `NotFoundFailure`).
class RequestPasswordResetUseCase implements UseCase<Unit, String> {
  final AuthRepository _repository;

  RequestPasswordResetUseCase(this._repository);

  @override
  Future<Either<Failure, Unit>> call(String email) async {
    final invalid = AuthRules.checkEmail(email);
    if (invalid != null) return Left(invalid);
    return _repository.requestPasswordReset(email.trim());
  }
}
