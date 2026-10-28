import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/network/api_client.dart';
import 'package:login_signup/core/session/session_service.dart';
import 'package:login_signup/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:login_signup/features/auth/data/datasources/google_auth_datasource.dart';
import 'package:login_signup/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:login_signup/features/auth/domain/repositories/auth_repository.dart';
import 'package:login_signup/features/auth/domain/usecases/google_sign_in_usecase.dart';
import 'package:login_signup/features/auth/domain/usecases/login_usecase.dart';
import 'package:login_signup/features/auth/domain/usecases/logout_usecase.dart';
import 'package:login_signup/features/auth/domain/usecases/register_usecase.dart';
import 'package:login_signup/features/auth/domain/usecases/request_password_reset_usecase.dart';
import 'package:login_signup/features/auth/domain/usecases/request_verification_code_usecase.dart';
import 'package:login_signup/features/auth/domain/usecases/reset_password_usecase.dart';
import 'package:login_signup/features/auth/domain/usecases/verify_email_usecase.dart';
import 'package:login_signup/shared/local_storage/local_storage.dart';

/// Datasources, repositorio y use cases de auth (ARQUITECTURA §4). Los
/// controllers los registran los bindings; `LogoutController` (alcance de
/// app), `UserModule`.
abstract final class AuthDependencies {
  static void init() {
    Get.lazyPut<AuthRemoteDataSource>(
      () => AuthRemoteDataSourceImpl(Get.find<Dio>(tag: apiClientTag)),
      fenix: true,
    );
    Get.lazyPut<GoogleAuthDataSource>(() => GoogleAuthDataSourceImpl(),
        fenix: true);
    Get.lazyPut<AuthRepository>(
      () => AuthRepositoryImpl(
        remote: Get.find<AuthRemoteDataSource>(),
        google: Get.find<GoogleAuthDataSource>(),
        session: Get.find<SessionService>(),
        localStorage: Get.find<LocalStorage>(),
      ),
      fenix: true,
    );

    Get.lazyPut(() => LoginUseCase(Get.find<AuthRepository>()), fenix: true);
    Get.lazyPut(() => RegisterUseCase(Get.find<AuthRepository>()), fenix: true);
    Get.lazyPut(() => GoogleSignInUseCase(Get.find<AuthRepository>()),
        fenix: true);
    Get.lazyPut(() => LogoutUseCase(Get.find<AuthRepository>()), fenix: true);
    Get.lazyPut(
        () => RequestVerificationCodeUseCase(Get.find<AuthRepository>()),
        fenix: true);
    Get.lazyPut(() => VerifyEmailUseCase(Get.find<AuthRepository>()),
        fenix: true);
    Get.lazyPut(() => RequestPasswordResetUseCase(Get.find<AuthRepository>()),
        fenix: true);
    Get.lazyPut(() => ResetPasswordUseCase(Get.find<AuthRepository>()),
        fenix: true);
  }
}
