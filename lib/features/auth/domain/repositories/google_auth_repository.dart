import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/features/auth/domain/entities/user_entity.dart';

abstract class GoogleAuthRepository {
  Future<Either<Failure, UserEntity>> signInWithGoogle();
}
