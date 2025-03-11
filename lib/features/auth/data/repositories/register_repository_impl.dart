// lib/features/auth/data/repositories/register_repository_impl.dart
import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/exceptions.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:login_signup/features/auth/domain/entities/user_entity.dart';
import 'package:login_signup/features/auth/domain/repositories/register_repository.dart';
import 'package:login_signup/shared/local_storage/local_storage.dart';

class RegisterRepositoryImpl implements RegisterRepository {
  final AuthRemoteDataSource remoteDataSource;
  final LocalStorage localStorage;

  RegisterRepositoryImpl({
    required this.remoteDataSource,
    required this.localStorage,
  });

  @override
  Future<Either<Failure, UserEntity>> register({
    required String name,
    required String lastname,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      // Llamar al datasource para registrar al usuario
      final userModel = await remoteDataSource.register(
        name: name,
        lastname: lastname,
        email: email,
        phone: phone,
        password: password,
      );

      // El token ya se guardó en el datasource, así que solo devolvemos el usuario
      return Right(userModel);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
