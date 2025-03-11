import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/exceptions.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/features/auth/data/datasources/google_auth_datasource.dart';
import 'package:login_signup/features/auth/domain/entities/user_entity.dart';
import 'package:login_signup/features/auth/domain/repositories/google_auth_repository.dart';

class GoogleAuthRepositoryImpl implements GoogleAuthRepository {
  final GoogleAuthDataSource googleAuthDataSource;

  GoogleAuthRepositoryImpl({
    required this.googleAuthDataSource,
  });

  @override
  Future<Either<Failure, UserEntity>> signInWithGoogle() async {
    try {
      final (userModel, _) = await googleAuthDataSource.signInWithGoogle();
      return Right(userModel);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
