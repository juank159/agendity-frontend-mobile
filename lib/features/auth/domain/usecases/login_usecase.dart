import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/features/auth/domain/entities/user_entity.dart';
import 'package:login_signup/features/auth/domain/repositories/auth_repository.dart';
import 'package:login_signup/features/auth/domain/usecases/auth_rules.dart';

class LoginParams {
  final String email;
  final String password;

  const LoginParams({required this.email, required this.password});
}

/// Inicia sesión con email y contraseña. Credenciales incorrectas →
/// `InvalidCredentialsFailure`; cuenta sin acceso → `AccountInactiveFailure`.
class LoginUseCase implements UseCase<UserEntity, LoginParams> {
  final AuthRepository _repository;

  LoginUseCase(this._repository);

  @override
  Future<Either<Failure, UserEntity>> call(LoginParams params) async {
    final invalid = AuthRules.checkEmail(params.email);
    if (invalid != null) return Left(invalid);
    return _repository.login(
        email: params.email.trim(), password: params.password);
  }
}
