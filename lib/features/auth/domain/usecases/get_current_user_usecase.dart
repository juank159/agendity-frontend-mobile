import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/features/auth/domain/entities/user_entity.dart';
import 'package:login_signup/features/auth/domain/repositories/auth_repository.dart';

/// Usuario de la sesión desde el backend (`GET /auth/me`): datos que el JWT
/// no trae, como `isEmailVerified`.
class GetCurrentUserUseCase extends UseCase<UserEntity, NoParams> {
  final AuthRepository repository;

  GetCurrentUserUseCase(this.repository);

  @override
  Future<Either<Failure, UserEntity>> call(NoParams params) =>
      repository.getCurrentUser();
}
