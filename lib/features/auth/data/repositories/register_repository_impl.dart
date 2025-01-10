import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/features/auth/data/datasources/register_local_datasource.dart';
import 'package:login_signup/features/auth/data/datasources/register_remote_datasource.dart';
import '../../domain/entities/user_entity.dart';

import '../../domain/repositories/register_repository.dart';

class RegisterRepositoryImpl implements RegisterRepository {
  final RegisterRemoteDataSource remoteDataSource;
  final RegisterLocalDataSource localDataSource;

  RegisterRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
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
      final (registerModel, token) = await remoteDataSource.register(
        name: name,
        lastname: lastname,
        email: email,
        phone: phone,
        password: password,
      );

      await localDataSource.saveToken(token);
      final user = UserEntity(
        id: registerModel.id,
        name: registerModel.name,
        lastname: registerModel.lastname,
        email: registerModel.email,
        phone: registerModel.phone,
      );
      return Right(user);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<void> saveToken(String token) async {
    try {
      await localDataSource.saveToken(token);
    } catch (e) {
      throw StorageFailure(message: 'Error al guardar el token');
    }
  }
}
