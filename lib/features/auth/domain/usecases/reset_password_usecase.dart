import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/features/auth/domain/failures/auth_failures.dart';
import 'package:login_signup/features/auth/domain/repositories/auth_repository.dart';
import 'package:login_signup/features/auth/domain/usecases/auth_rules.dart';

class ResetPasswordParams {
  final String email;
  final String code;
  final String newPassword;

  const ResetPasswordParams({
    required this.email,
    required this.code,
    required this.newPassword,
  });
}

/// Cambia la contraseña con el código de recuperación. Código incorrecto,
/// vencido o agotado → `InvalidVerificationCodeFailure` (core).
class ResetPasswordUseCase implements UseCase<Unit, ResetPasswordParams> {
  final AuthRepository _repository;

  ResetPasswordUseCase(this._repository);

  @override
  Future<Either<Failure, Unit>> call(ResetPasswordParams params) async {
    final invalid = AuthRules.checkEmail(params.email);
    if (invalid != null) return Left(invalid);
    final code = params.code.trim();
    if (code.isEmpty) {
      return const Left(InvalidAuthDataFailure(message: AuthRules.missingCode));
    }
    return _repository.resetPassword(
        email: params.email.trim(),
        code: code,
        newPassword: params.newPassword);
  }
}
