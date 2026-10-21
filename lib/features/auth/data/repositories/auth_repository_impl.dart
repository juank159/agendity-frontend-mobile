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
      print('AuthRepositoryImpl: Login exitoso para ${userModel.email}');
      return Right(userModel);
    } on ServerException catch (e) {
      print(
          'AuthRepositoryImpl: Capturada ServerException. Mensaje: ${e.message}');
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      print(
          'AuthRepositoryImpl: Capturada excepción inesperada en login: ${e.runtimeType} - ${e.toString()}');
      return Left(ServerFailure(
          message: 'Error inesperado en repositorio: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      print('Iniciando proceso de cierre de sesión...');

      // Primero eliminamos el token local
      await _localStorage.deleteToken();
      print('Token eliminado del localStorage');

      // Limpiar todos los datos almacenados
      await _localStorage.clearAllData();
      print('Todos los datos han sido limpiados');

      print('Proceso de cierre de sesión completado');
      return const Right(null);
    } catch (e) {
      print('Error en signOut del repositorio: $e');
      return Left(
          ServerFailure(message: 'Error al cerrar sesión: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, bool>> logout() async {
    try {
      // Reutilizar la lógica de signOut
      final result = await signOut();
      return result.fold(
        (failure) => Left(failure),
        (_) => const Right(true),
      );
    } catch (e) {
      return Left(
          ServerFailure(message: 'Error al cerrar sesión: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> register({
    required String name,
    required String lastname,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      final userModel = await _remoteDataSource.register(
        name: name,
        lastname: lastname,
        email: email,
        phone: phone,
        password: password,
      );

      print('AuthRepositoryImpl: Registro exitoso para ${userModel.email}');
      return Right(userModel);
    } on ServerException catch (e) {
      print('AuthRepositoryImpl: Error en registro. Mensaje: ${e.message}');
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      print(
          'AuthRepositoryImpl: Error inesperado en registro: ${e.toString()}');
      return Left(ServerFailure(
          message: 'Error inesperado en registro: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> requestVerificationCode({
    required String email,
    bool isNewUser = false,
  }) async {
    try {
      await _remoteDataSource.requestVerificationCode(
        email: email,
        isNewUser: isNewUser,
      );
      print(
          'AuthRepositoryImpl: Código de verificación solicitado para $email');
      return const Right(null);
    } on ServerException catch (e) {
      print(
          'AuthRepositoryImpl: Error solicitando código de verificación. Mensaje: ${e.message}');
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      print(
          'AuthRepositoryImpl: Error inesperado solicitando código: ${e.toString()}');
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> verifyEmail({
    required String email,
    required String code,
  }) async {
    try {
      final result = await _remoteDataSource.verifyEmail(
        email: email,
        code: code,
      );
      print('AuthRepositoryImpl: Email verificado exitosamente para $email');
      return Right(result);
    } on ServerException catch (e) {
      // Asegúrate de que solo los errores reales (códigos 4xx, 5xx) se traduzcan en Failure
      if (e.statusCode == null ||
          (e.statusCode != null && e.statusCode! >= 400)) {
        print(
            'AuthRepositoryImpl: Error verificando email. Mensaje: ${e.message}');
        return Left(ServerFailure(message: e.message));
      }
      // Si llegamos aquí con un código 2xx, algo salió mal en la lógica
      return const Right(true);
    } catch (e) {
      print(
          'AuthRepositoryImpl: Error inesperado verificando email: ${e.toString()}');
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> requestPasswordReset({
    required String email,
  }) async {
    try {
      await _remoteDataSource.requestPasswordReset(email: email);
      print(
          'AuthRepositoryImpl: Código de recuperación solicitado para $email');
      return const Right(null);
    } on ServerException catch (e) {
      print(
          'AuthRepositoryImpl: Error solicitando código de recuperación. Mensaje: ${e.message}');
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      print(
          'AuthRepositoryImpl: Error inesperado solicitando código de recuperación: ${e.toString()}');
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
      print(
          'AuthRepositoryImpl: Contraseña restablecida exitosamente para $email');
      return Right(result);
    } on ServerException catch (e) {
      print(
          'AuthRepositoryImpl: Error restableciendo contraseña. Mensaje: ${e.message}');
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      print(
          'AuthRepositoryImpl: Error inesperado restableciendo contraseña: ${e.toString()}');
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
