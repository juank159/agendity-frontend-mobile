// // lib/features/auth/domain/repositories/auth_repository.dart
// import 'package:dartz/dartz.dart';
// import '../../../../core/errors/failures.dart';
// import '../entities/user_entity.dart';

// abstract class AuthRepository {
//   Future<Either<Failure, UserEntity>> login({
//     required String email,
//     required String password,
//   });

//   Future<Either<Failure, void>> signOut();
// }

// lib/features/auth/domain/repositories/auth_repository.dart
import 'package:dartz/dartz.dart';
import 'package:login_signup/features/auth/domain/entities/user_entity.dart';
import '../../../../core/errors/failures.dart';

abstract class AuthRepository {
  Future<Either<Failure, UserEntity>> login({
    required String email,
    required String password,
  });

  Future<Either<Failure, bool>> logout();

  Future<Either<Failure, UserEntity>> register({
    required String name,
    required String lastname,
    required String email,
    required String phone,
    required String password,
  });

  Future<Either<Failure, void>> signOut();
  Future<Either<Failure, bool>> requestVerificationCode(
      {required String email});
  Future<Either<Failure, bool>> verifyEmail(
      {required String email, required String code});

  Future<Either<Failure, bool>> requestPasswordReset({required String email});
  Future<Either<Failure, bool>> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  });
}
