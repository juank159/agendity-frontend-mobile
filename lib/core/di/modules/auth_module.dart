import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/config/api_config.dart';
import 'package:login_signup/core/config/env_config.dart';
import 'package:login_signup/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:login_signup/features/auth/data/datasources/google_auth_datasource.dart';
import 'package:login_signup/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:login_signup/features/auth/data/repositories/google_auth_repository_impl.dart';
import 'package:login_signup/features/auth/data/repositories/register_repository_impl.dart';
import 'package:login_signup/features/auth/domain/repositories/auth_repository.dart';
import 'package:login_signup/features/auth/domain/repositories/google_auth_repository.dart';
import 'package:login_signup/features/auth/domain/repositories/register_repository.dart';
import 'package:login_signup/features/auth/domain/services/auth_service.dart';
import 'package:login_signup/features/auth/domain/usecases/google_sign_in_usecase.dart';
import 'package:login_signup/features/auth/domain/usecases/login_usecase.dart';
import 'package:login_signup/features/auth/domain/usecases/logout_usecase.dart';
import 'package:login_signup/features/auth/domain/usecases/register_usecase.dart';
import 'package:login_signup/features/auth/domain/usecases/request_verification_code_usecase.dart';
import 'package:login_signup/features/auth/domain/usecases/reset_password_usecase.dart';
import 'package:login_signup/features/auth/domain/usecases/verify_email_usecase.dart';
import 'package:login_signup/features/auth/presentation/controllers/email_verification_controller.dart';
import 'package:login_signup/features/auth/presentation/controllers/google_auth_controller.dart';
import 'package:login_signup/features/auth/presentation/controllers/login_controller.dart';
import 'package:login_signup/features/auth/presentation/controllers/logout_controller.dart';
import 'package:login_signup/features/auth/presentation/controllers/register_controller.dart';
import 'package:login_signup/features/auth/presentation/controllers/reset_password_controller.dart';
import 'package:login_signup/shared/local_storage/local_storage.dart';

class AuthModule {
  static Future<void> init() async {
    try {
      // Primero verificamos si Dio ya está registrado
      if (!Get.isRegistered<Dio>()) {
        // Si no está registrado, intentamos inicializar las dependencias core
        final dio = ApiConfig.createDio(EnvConfig.apiUrl);
        Get.put<Dio>(dio, permanent: true);
      }

      // Verificamos si LocalStorage ya está registrado
      if (!Get.isRegistered<LocalStorage>()) {
        if (!Get.isRegistered<FlutterSecureStorage>()) {
          Get.put<FlutterSecureStorage>(const FlutterSecureStorage(),
              permanent: true);
        }
        Get.put<LocalStorage>(LocalStorage(Get.find()), permanent: true);
      }

      // Ahora obtenemos las dependencias necesarias
      final dio = Get.find<Dio>();
      final localStorage = Get.find<LocalStorage>();

      // 1. DataSources
      if (!Get.isRegistered<AuthRemoteDataSource>()) {
        Get.put<AuthRemoteDataSource>(
          AuthRemoteDataSource(
            dio: dio,
            localStorage: localStorage,
          ),
          permanent: true,
        );
      }

      // Google Auth DataSource
      if (!Get.isRegistered<GoogleAuthDataSource>()) {
        Get.put<GoogleAuthDataSource>(
          GoogleAuthDataSourceImpl(
            dio: dio,
            localStorage: localStorage,
          ),
          permanent: true,
        );
      }

      // 2. Repositories
      if (!Get.isRegistered<AuthRepository>()) {
        Get.put<AuthRepository>(
          AuthRepositoryImpl(
            remoteDataSource: Get.find(),
            localStorage: localStorage,
          ),
          permanent: true,
        );
      }

      // Google Auth Repository
      if (!Get.isRegistered<GoogleAuthRepository>()) {
        Get.put<GoogleAuthRepository>(
          GoogleAuthRepositoryImpl(
            googleAuthDataSource: Get.find(),
          ),
          permanent: true,
        );
      }

      // Register Repository
      if (!Get.isRegistered<RegisterRepository>()) {
        Get.put<RegisterRepository>(
          RegisterRepositoryImpl(
            remoteDataSource: Get.find<AuthRemoteDataSource>(),
            localStorage: localStorage,
          ),
          permanent: true,
        );
      }

      // 3. Service
      if (!Get.isRegistered<AuthService>()) {
        Get.put<AuthService>(
          AuthService(localStorage: localStorage),
          permanent: true,
        );
      }

      // 4. UseCases
      if (!Get.isRegistered<LoginUseCase>()) {
        Get.put<LoginUseCase>(
          LoginUseCase(Get.find()),
          permanent: true,
        );
      }

      if (!Get.isRegistered<LogoutUseCase>()) {
        Get.put<LogoutUseCase>(
          LogoutUseCase(Get.find()),
          permanent: true,
        );
      }

      // Registro UseCase
      if (!Get.isRegistered<RegisterUseCase>()) {
        Get.put<RegisterUseCase>(
          RegisterUseCase(Get.find()),
          permanent: true,
        );
      }

      // Google Sign In UseCase
      if (!Get.isRegistered<GoogleSignInUseCase>()) {
        Get.put<GoogleSignInUseCase>(
          GoogleSignInUseCase(Get.find()),
          permanent: true,
        );
      }

      // 5. Controllers
      if (!Get.isRegistered<LoginController>()) {
        Get.put<LoginController>(
          LoginController(loginUseCase: Get.find()),
          permanent: true,
        );
      }

      if (!Get.isRegistered<LogoutController>()) {
        Get.put<LogoutController>(
          LogoutController(logoutUseCase: Get.find()),
          permanent: true,
        );
      }

      // Register Controller
      if (!Get.isRegistered<RegisterController>()) {
        Get.put<RegisterController>(
          RegisterController(registerUseCase: Get.find()),
          permanent: true,
        );
      }

      // Google Auth Controller
      if (!Get.isRegistered<GoogleAuthController>()) {
        Get.put<GoogleAuthController>(
          GoogleAuthController(googleSignInUseCase: Get.find()),
          permanent: true,
        );
      }

      // Registrar casos de uso de verificación
      Get.lazyPut<RequestVerificationCodeUseCase>(
        () => RequestVerificationCodeUseCase(Get.find()),
        fenix: true,
      );

      Get.lazyPut<VerifyEmailUseCase>(
        () => VerifyEmailUseCase(Get.find()),
        fenix: true,
      );

      // Registrar controlador de verificación
      Get.lazyPut<EmailVerificationController>(
        () => EmailVerificationController(
          requestCodeUseCase: Get.find(),
          verifyEmailUseCase: Get.find(),
        ),
        fenix: true,
      );
      if (!Get.isRegistered<ResetPasswordUseCase>()) {
        Get.put<ResetPasswordUseCase>(
          ResetPasswordUseCase(Get.find()),
          permanent: true,
        );
      }
    } catch (e) {
      print('Error initializing AuthModule: $e');
      rethrow;
    }
  }

  static void cleanupResetPasswordResources() {
    // Asegurarse que cualquier TextEditingController en el ResetPasswordController se libere
    try {
      if (Get.isRegistered<ResetPasswordController>()) {
        final controller = Get.find<ResetPasswordController>();

        // Liberar manualmente los controladores antes de eliminar la instancia
        // Ya no hay codeController, solo password y confirmPassword
        try {
          controller.passwordController.dispose();
          controller.confirmPasswordController.dispose();
        } catch (e) {
          print('Error al liberar controladores de texto: $e');
        }

        // Ahora eliminamos la instancia
        Get.delete<ResetPasswordController>(force: true);
      }
    } catch (e) {
      print('Error al limpiar ResetPasswordController: $e');
    }

    // También eliminar el caso de uso para evitar referencias circulares
    try {
      if (Get.isRegistered<ResetPasswordUseCase>()) {
        Get.delete<ResetPasswordUseCase>(force: true);
      }
    } catch (e) {
      print('Error al limpiar ResetPasswordUseCase: $e');
    }

    // Limpiar cualquier Snackbar abierto
    if (Get.isSnackbarOpen) {
      Get.closeAllSnackbars();
    }

    print('Recursos de restablecimiento de contraseña liberados correctamente');
  }
}
