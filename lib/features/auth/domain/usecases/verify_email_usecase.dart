import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/features/auth/domain/failures/auth_failures.dart';
import 'package:login_signup/features/auth/domain/repositories/auth_repository.dart';
import 'package:login_signup/features/auth/domain/usecases/auth_rules.dart';

class VerifyEmailParams {
  final String email;
  final String code;

  const VerifyEmailParams({required this.email, required this.code});
}

/// Verifica el email con el código. Código incorrecto, vencido o agotado →
/// `InvalidVerificationCodeFailure` (core) con el motivo del backend.
class VerifyEmailUseCase implements UseCase<Unit, VerifyEmailParams> {
  final AuthRepository _repository;

  VerifyEmailUseCase(this._repository);

  @override
  Future<Either<Failure, Unit>> call(VerifyEmailParams params) async {
    final invalid = AuthRules.checkEmail(params.email);
    if (invalid != null) return Left(invalid);
    final code = params.code.trim();
    if (code.isEmpty) {
      return const Left(InvalidAuthDataFailure(message: AuthRules.missingCode));
    }
    return _repository.verifyEmail(email: params.email.trim(), code: code);
  }
}
