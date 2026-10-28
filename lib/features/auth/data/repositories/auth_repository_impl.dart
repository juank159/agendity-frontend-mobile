import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/network/safe_call.dart';
import 'package:login_signup/core/session/session_service.dart';
import 'package:login_signup/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:login_signup/features/auth/data/datasources/google_auth_datasource.dart';
import 'package:login_signup/features/auth/data/models/user_model.dart';
import 'package:login_signup/features/auth/domain/entities/register_owner_input.dart';
import 'package:login_signup/features/auth/domain/entities/user_entity.dart';
import 'package:login_signup/features/auth/domain/failures/auth_failures.dart';
import 'package:login_signup/features/auth/domain/repositories/auth_repository.dart';
import 'package:login_signup/shared/local_storage/local_storage.dart';
import 'package:login_signup/core/utils/app_logger.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remote;
  final GoogleAuthDataSource _google;
  final SessionService _session;
  final LocalStorage _localStorage;

  AuthRepositoryImpl({
    required AuthRemoteDataSource remote,
    required GoogleAuthDataSource google,
    required SessionService session,
    required LocalStorage localStorage,
  })  : _remote = remote,
        _google = google,
        _session = session,
        _localStorage = localStorage;

  @override
  Future<Either<Failure, UserEntity>> login({
    required String email,
    required String password,
  }) =>
      safeCall(() async => _start(await _remote.login(email, password)),
          refine: _refineLogin);

  @override
  Future<Either<Failure, UserEntity>> registerOwner(RegisterOwnerInput input) =>
      safeCall(() async => _start(await _remote.registerOwner(input)));

  @override
  Future<Either<Failure, UserEntity>> signInWithGoogle() async {
    final String? idToken;
    try {
      idToken = await _google.obtainIdToken();
    } catch (error) {
      AppLogger.error('Google Sign-In', error.runtimeType);
      return const Left(GoogleSignInRejectedFailure());
    }
    if (idToken == null) return const Left(GoogleSignInCancelledFailure());
    return safeCall(() async => _start(await _remote.googleLogin(idToken!)),
        refine: _refineGoogle);
  }

  @override
  Future<Either<Failure, Unit>> requestVerificationCode(String email) =>
      safeCall(() async {
        await _remote.requestVerificationCode(email);
        return unit;
      });

  @override
  Future<Either<Failure, Unit>> verifyEmail({
    required String email,
    required String code,
  }) =>
      safeCall(() async {
        await _remote.verifyEmail(email, code);
        return unit;
      });

  @override
  Future<Either<Failure, Unit>> requestPasswordReset(String email) =>
      safeCall(() async {
        await _remote.requestPasswordReset(email);
        return unit;
      });

  @override
  Future<Either<Failure, Unit>> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) =>
      safeCall(() async {
        await _remote.resetPassword(email, code, newPassword);
        return unit;
      });

  @override
  Future<Either<Failure, Unit>> logout() => safeCall(() async {
        await _session.end();
        await _localStorage.clearAllData();
        try {
          await _google.signOut();
        } catch (_) {
          // Sin sesión de Google (o sin plugin): no impide cerrar la sesión.
        }
        return unit;
      });

  /// Guarda el JWT de Agendity (lanza `FormatException` si no es válido, y
  /// entonces no queda sesión) y devuelve el usuario de la respuesta.
  Future<UserEntity> _start(AuthResponseModel response) async {
    await _session.start(response.token);
    return response.user.toEntity();
  }

  static Failure _refineLogin(Failure failure) => switch (failure) {
        _ when failure.code == ApiErrorCode.accountInactive =>
          _accountInactive(failure),
        UnauthorizedFailure() => InvalidCredentialsFailure(
            message: failure.message,
            code: failure.code,
            statusCode: failure.statusCode,
            details: failure.details),
        _ => failure,
      };

  static Failure _refineGoogle(Failure failure) => switch (failure) {
        _ when failure.code == ApiErrorCode.accountInactive =>
          _accountInactive(failure),
        UnauthorizedFailure() => GoogleSignInRejectedFailure(
            message: failure.message,
            code: failure.code,
            statusCode: failure.statusCode,
            details: failure.details),
        _ => failure,
      };

  static Failure _accountInactive(Failure failure) => AccountInactiveFailure(
      message: failure.message,
      statusCode: failure.statusCode,
      details: failure.details);
}
