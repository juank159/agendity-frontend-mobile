import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import '../entities/user_entity.dart';

abstract class RegisterRepository {
  Future<Either<Failure, UserEntity>> register({
    required String name,
    required String lastname,
    required String email,
    required String phone,
    required String password,
  });

  Future<void> saveToken(String token);
}
