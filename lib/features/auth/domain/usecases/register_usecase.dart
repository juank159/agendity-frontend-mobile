import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/features/auth/domain/entities/register_owner_input.dart';
import 'package:login_signup/features/auth/domain/entities/user_entity.dart';
import 'package:login_signup/features/auth/domain/repositories/auth_repository.dart';
import 'package:login_signup/features/auth/domain/usecases/auth_rules.dart';

/// Registra un negocio (Owner + trial) e inicia su sesión. Email o teléfono
/// repetidos → `DuplicateEmailFailure`/`DuplicatePhoneFailure`.
class RegisterUseCase implements UseCase<UserEntity, RegisterOwnerInput> {
  final AuthRepository _repository;

  RegisterUseCase(this._repository);

  @override
  Future<Either<Failure, UserEntity>> call(RegisterOwnerInput params) async {
    final input = params.normalized();
    final invalid = AuthRules.checkEmail(input.email);
    if (invalid != null) return Left(invalid);
    return _repository.registerOwner(input);
  }
}
