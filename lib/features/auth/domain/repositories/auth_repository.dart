import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/features/auth/domain/entities/register_owner_input.dart';
import 'package:login_signup/features/auth/domain/entities/user_entity.dart';

/// Único contrato de autenticación: login, registro, Google, códigos y logout.
///
/// Login, registro y Google **inician la sesión** (guardan el JWT de Agendity
/// con `SessionService.start`) antes de devolver el usuario; si fallan, no
/// queda ninguna sesión. Errores por `code` (§3): credenciales →
/// `InvalidCredentialsFailure`, cuenta sin acceso → `AccountInactiveFailure`,
/// código malo → `InvalidVerificationCodeFailure`, throttle →
/// `TooManyRequestsFailure`, repetidos → `DuplicateEmail/PhoneFailure`.
abstract class AuthRepository {
  /// `POST /auth/login`.
  Future<Either<Failure, UserEntity>> login({
    required String email,
    required String password,
  });

  /// `POST /auth/register/owner`: crea el negocio (Owner + trial, 2.19).
  Future<Either<Failure, UserEntity>> registerOwner(RegisterOwnerInput input);

  /// Selector de Google + `POST /auth/google` con el ID token. Se usa el JWT
  /// de Agendity de la respuesta; el token de Google nunca es la sesión.
  Future<Either<Failure, UserEntity>> signInWithGoogle();

  /// `POST /auth/verify/request-code` (email desconocido → `NotFoundFailure`).
  Future<Either<Failure, Unit>> requestVerificationCode(String email);

  /// `POST /auth/verify/email`.
  Future<Either<Failure, Unit>> verifyEmail({
    required String email,
    required String code,
  });

  /// `POST /auth/forgot-password`.
  Future<Either<Failure, Unit>> requestPasswordReset(String email);

  /// `POST /auth/reset-password`.
  Future<Either<Failure, Unit>> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  });

  /// Único logout: borra la sesión, los datos locales y la sesión de Google.
  Future<Either<Failure, Unit>> logout();
}
