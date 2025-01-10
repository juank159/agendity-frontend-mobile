import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import '../entities/user_entity.dart';
import '../repositories/register_repository.dart';

class RegisterUseCase {
  final RegisterRepository repository;

  RegisterUseCase(this.repository);

  Future<Either<Failure, UserEntity>> call({
    required String name,
    required String lastname,
    required String email,
    required String phone,
    required String password,
  }) async {
    return await repository.register(
      name: name,
      lastname: lastname,
      email: email,
      phone: phone,
      password: password,
    );
  }
}
