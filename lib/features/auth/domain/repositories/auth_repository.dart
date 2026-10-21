// import 'package:dartz/dartz.dart';
// import '../../../../core/errors/failures.dart';
// import '../entities/user_entity.dart';

// /// Repositorio de autenticación - Contrato/Interface
// ///
// /// Define todas las operaciones de autenticación disponibles en la aplicación
// /// Implementado por AuthRepositoryImpl en la capa de datos
// abstract class AuthRepository {
//   /// Iniciar sesión con email y contraseña
//   Future<Either<Failure, UserEntity>> login({
//     required String email,
//     required String password,
//   });

//   /// Cerrar sesión del usuario actual
//   Future<Either<Failure, void>> signOut();

//   /// Registrar nuevo usuario
//   Future<Either<Failure, UserEntity>> register({
//     required String name,
//     required String lastname,
//     required String email,
//     required String phone,
//     required String password,
//   });

//   /// Solicitar código de verificación por email
//   ///
//   /// [email] - Email al que enviar el código
//   /// [isNewUser] - true para nuevos usuarios, false para existentes
//   Future<Either<Failure, bool>> requestVerificationCode({
//     required String email,
//     bool isNewUser = false,
//   });

//   /// Verificar email con código recibido
//   Future<Either<Failure, bool>> verifyEmail({
//     required String email,
//     required String code,
//   });

//   /// Solicitar código para restablecer contraseña
//   Future<Either<Failure, bool>> requestPasswordReset({
//     required String email,
//   });

//   /// Restablecer contraseña con código
//   Future<Either<Failure, bool>> resetPassword({
//     required String email,
//     required String code,
//     required String newPassword,
//   });

//   /// Cerrar sesión (alias de signOut para compatibilidad)
//   Future<Either<Failure, bool>> logout();
// }

import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user_entity.dart';

/// Repositorio de autenticación - Contrato/Interface
///
/// Define todas las operaciones de autenticación disponibles en la aplicación
/// Implementado por AuthRepositoryImpl en la capa de datos
abstract class AuthRepository {
  /// Iniciar sesión con email y contraseña
  Future<Either<Failure, UserEntity>> login({
    required String email,
    required String password,
  });

  /// Cerrar sesión del usuario actual
  Future<Either<Failure, void>> signOut();

  /// Registrar nuevo usuario
  Future<Either<Failure, UserEntity>> register({
    required String name,
    required String lastname,
    required String email,
    required String phone,
    required String password,
  });

  /// Solicitar código de verificación por email
  ///
  /// [email] - Email al que enviar el código
  /// [isNewUser] - true para nuevos usuarios, false para existentes
  Future<Either<Failure, void>> requestVerificationCode({
    required String email,
    bool isNewUser = false,
  });

  /// Verificar email con código recibido
  Future<Either<Failure, bool>> verifyEmail({
    required String email,
    required String code,
  });

  /// Solicitar código para restablecer contraseña
  Future<Either<Failure, void>> requestPasswordReset({
    required String email,
  });

  /// Restablecer contraseña con código
  Future<Either<Failure, bool>> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  });

  /// Cerrar sesión (alias de signOut para compatibilidad)
  Future<Either<Failure, bool>> logout();
}
