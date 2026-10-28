import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/features/auth/domain/entities/user_entity.dart';
import 'package:login_signup/features/auth/domain/repositories/auth_repository.dart';

/// Login (o alta de un negocio nuevo) con Google. Cancelado →
/// `GoogleSignInCancelledFailure`; rechazado por el backend →
/// `GoogleSignInRejectedFailure` o `AccountInactiveFailure`, sin sesión.
class GoogleSignInUseCase implements UseCase<UserEntity, NoParams> {
  final AuthRepository _repository;

  GoogleSignInUseCase(this._repository);

  @override
  Future<Either<Failure, UserEntity>> call(NoParams params) =>
      _repository.signInWithGoogle();
}
