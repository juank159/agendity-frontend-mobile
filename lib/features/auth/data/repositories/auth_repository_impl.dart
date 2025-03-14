// // lib/features/auth/data/repositories/auth_repository_impl.dart
// import 'package:dartz/dartz.dart';
// import '../../../../core/errors/failures.dart';
// import '../../domain/entities/user_entity.dart';
// import '../../domain/repositories/auth_repository.dart';
// import '../datasources/auth_remote_datasource.dart';
// import '../models/user_model.dart';
// import '../../../../shared/local_storage/local_storage.dart';

// class AuthRepositoryImpl implements AuthRepository {
//   final AuthRemoteDataSource _remoteDataSource;
//   final LocalStorage _localStorage;

//   AuthRepositoryImpl({
//     required AuthRemoteDataSource remoteDataSource,
//     required LocalStorage localStorage,
//   })  : _remoteDataSource = remoteDataSource,
//         _localStorage = localStorage;

//   @override
//   Future<Either<Failure, UserEntity>> login({
//     required String email,
//     required String password,
//   }) async {
//     try {
//       final response = await _remoteDataSource.login(
//         email: email,
//         password: password,
//       );

//       // Guardar token en el almacenamiento local
//       await _localStorage.saveToken(response['token']);

//       // Convertir respuesta a UserModel
//       final userModel = UserModel.fromJson(response);
//       return Right(userModel);
//     } catch (e) {
//       return Left(ServerFailure(message: e.toString()));
//     }
//   }

//   @override
//   Future<Either<Failure, void>> signOut() async {
//     try {
//       print('Iniciando proceso de cierre de sesión...'); // Debug

//       // Primero eliminamos el token local
//       await _localStorage.deleteToken();
//       print('Token eliminado del localStorage'); // Debug

//       // Limpiar todos los datos almacenados
//       await _localStorage.clearAllData();
//       print('Todos los datos han sido limpiados'); // Debug

//       print('Proceso de cierre de sesión completado'); // Debug
//       return const Right(null);
//     } catch (e) {
//       print('Error en signOut del repositorio: $e'); // Debug
//       return Left(
//           ServerFailure(message: 'Error al cerrar sesión: ${e.toString()}'));
//     }
//   }
// }

// lib/features/auth/data/repositories/auth_repository_impl.dart
import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/user_model.dart';
import '../../../../shared/local_storage/local_storage.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final LocalStorage _localStorage;

  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required LocalStorage localStorage,
  })  : _remoteDataSource = remoteDataSource,
        _localStorage = localStorage;

  @override
  Future<Either<Failure, UserEntity>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _remoteDataSource.login(
        email: email,
        password: password,
      );

      // Guardar token en el almacenamiento local
      await _localStorage.saveToken(response['token']);

      // Convertir respuesta a UserModel
      final userModel = UserModel.fromJson(response);
      return Right(userModel);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      print('Iniciando proceso de cierre de sesión...'); // Debug

      // Primero eliminamos el token local
      await _localStorage.deleteToken();
      print('Token eliminado del localStorage'); // Debug

      // Limpiar todos los datos almacenados
      await _localStorage.clearAllData();
      print('Todos los datos han sido limpiados'); // Debug

      print('Proceso de cierre de sesión completado'); // Debug
      return const Right(null);
    } catch (e) {
      print('Error en signOut del repositorio: $e'); // Debug
      return Left(
          ServerFailure(message: 'Error al cerrar sesión: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, bool>> logout() {
    // TODO: implement logout
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, UserEntity>> register(
      {required String name,
      required String lastname,
      required String email,
      required String phone,
      required String password}) {
    // TODO: implement register
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, bool>> requestVerificationCode(
      {required String email}) async {
    try {
      await _remoteDataSource.requestVerificationCode(email: email);
      return const Right(true);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> verifyEmail(
      {required String email, required String code}) async {
    try {
      final result =
          await _remoteDataSource.verifyEmail(email: email, code: code);
      return Right(result);
    } catch (e) {
      if (e is ServerException) {
        // Asegúrate de que solo los errores reales (códigos 4xx, 5xx) se traduzcan en Failure
        if (e.statusCode == null ||
            (e.statusCode != null && e.statusCode! >= 400)) {
          return Left(ServerFailure(message: e.message));
        }
        // Si llegamos aquí con un código 2xx, algo salió mal en la lógica
        return const Right(true);
      }
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> requestPasswordReset(
      {required String email}) async {
    try {
      await _remoteDataSource.requestPasswordReset(email: email);
      return const Right(true);
    } catch (e) {
      if (e is ServerException) {
        return Left(ServerFailure(message: e.message));
      }
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      final result = await _remoteDataSource.resetPassword(
        email: email,
        code: code,
        newPassword: newPassword,
      );
      return Right(result);
    } catch (e) {
      if (e is ServerException) {
        return Left(ServerFailure(message: e.message));
      }
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
