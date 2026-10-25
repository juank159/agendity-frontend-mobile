// import 'package:dio/dio.dart';
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// import 'package:get/get.dart';
// import 'package:login_signup/core/config/api_config.dart';
// import 'package:login_signup/core/config/env_config.dart';
// import 'package:login_signup/features/auth/data/datasources/auth_remote_datasource.dart';
// import 'package:login_signup/features/auth/data/datasources/google_auth_datasource.dart';
// import 'package:login_signup/features/auth/data/repositories/auth_repository_impl.dart';
// import 'package:login_signup/features/auth/data/repositories/google_auth_repository_impl.dart';
// import 'package:login_signup/features/auth/data/repositories/register_repository_impl.dart';
// import 'package:login_signup/features/auth/domain/repositories/auth_repository.dart';
// import 'package:login_signup/features/auth/domain/repositories/google_auth_repository.dart';
// import 'package:login_signup/features/auth/domain/repositories/register_repository.dart';
// import 'package:login_signup/features/auth/domain/services/auth_service.dart';
// import 'package:login_signup/features/auth/domain/usecases/google_sign_in_usecase.dart';
// import 'package:login_signup/features/auth/domain/usecases/login_usecase.dart';
// import 'package:login_signup/features/auth/domain/usecases/logout_usecase.dart';
// import 'package:login_signup/features/auth/domain/usecases/register_usecase.dart';
// import 'package:login_signup/features/auth/domain/usecases/request_verification_code_usecase.dart';
// import 'package:login_signup/features/auth/domain/usecases/reset_password_usecase.dart';
// import 'package:login_signup/features/auth/domain/usecases/verify_email_usecase.dart';

// import 'package:login_signup/features/auth/presentation/controllers/google_auth_controller.dart';
// import 'package:login_signup/features/auth/presentation/controllers/login_controller.dart';
// import 'package:login_signup/features/auth/presentation/controllers/logout_controller.dart';
// import 'package:login_signup/features/auth/presentation/controllers/register_controller.dart';
// import 'package:login_signup/features/auth/presentation/controllers/reset_password_controller.dart';
// import 'package:login_signup/shared/local_storage/local_storage.dart';

// class AuthModule {
//   static Future<void> init() async {
//     try {
//       print('🔄 Inicializando AuthModule...');

//       // PASO 1: CORE DEPENDENCIES
//       await _initCoreDependencies();

//       // PASO 2: DATA SOURCES
//       _initDataSources();

//       // PASO 3: REPOSITORIES
//       _initRepositories();

//       // PASO 4: SERVICES
//       _initServices();

//       // PASO 5: USE CASES
//       _initUseCases();

//       // PASO 6: CONTROLLERS
//       _initControllers();

//       print('✅ AuthModule inicializado correctamente');
//     } catch (e) {
//       print('❌ Error inicializando AuthModule: $e');
//       rethrow;
//     }
//   }

//   // PASO 1: CORE DEPENDENCIES
//   static Future<void> _initCoreDependencies() async {
//     // Verificar si Dio ya está registrado
//     if (!Get.isRegistered<Dio>()) {
//       final dio = ApiConfig.createDio(EnvConfig.apiUrl);
//       Get.put<Dio>(dio, permanent: true);
//       print('📡 Dio registrado');
//     }

//     // Verificar si LocalStorage ya está registrado
//     if (!Get.isRegistered<LocalStorage>()) {
//       if (!Get.isRegistered<FlutterSecureStorage>()) {
//         Get.put<FlutterSecureStorage>(const FlutterSecureStorage(),
//             permanent: true);
//         print('🔐 FlutterSecureStorage registrado');
//       }
//       Get.put<LocalStorage>(LocalStorage(Get.find()), permanent: true);
//       print('💾 LocalStorage registrado');
//     }
//   }

//   // PASO 2: DATA SOURCES
//   static void _initDataSources() {
//     // Auth Remote DataSource
//     if (!Get.isRegistered<AuthRemoteDataSource>()) {
//       Get.put<AuthRemoteDataSource>(
//         AuthRemoteDataSource(
//           dio: Get.find<Dio>(),
//           localStorage: Get.find<LocalStorage>(),
//         ),
//         permanent: true,
//       );
//       print('📡 AuthRemoteDataSource registrado');
//     }

//     // Google Auth DataSource
//     if (!Get.isRegistered<GoogleAuthDataSource>()) {
//       Get.put<GoogleAuthDataSource>(
//         GoogleAuthDataSourceImpl(
//           dio: Get.find<Dio>(),
//           localStorage: Get.find<LocalStorage>(),
//         ),
//         permanent: true,
//       );
//       print('🌐 GoogleAuthDataSource registrado');
//     }
//   }

//   // PASO 3: REPOSITORIES
//   static void _initRepositories() {
//     // Auth Repository
//     if (!Get.isRegistered<AuthRepository>()) {
//       Get.put<AuthRepository>(
//         AuthRepositoryImpl(
//           remoteDataSource: Get.find<AuthRemoteDataSource>(),
//           localStorage: Get.find<LocalStorage>(),
//         ),
//         permanent: true,
//       );
//       print('🏛️ AuthRepository registrado');
//     }

//     // Google Auth Repository
//     if (!Get.isRegistered<GoogleAuthRepository>()) {
//       Get.put<GoogleAuthRepository>(
//         GoogleAuthRepositoryImpl(
//           googleAuthDataSource: Get.find<GoogleAuthDataSource>(),
//         ),
//         permanent: true,
//       );
//       print('🌐 GoogleAuthRepository registrado');
//     }

//     // Register Repository
//     if (!Get.isRegistered<RegisterRepository>()) {
//       Get.put<RegisterRepository>(
//         RegisterRepositoryImpl(
//           remoteDataSource: Get.find<AuthRemoteDataSource>(),
//           localStorage: Get.find<LocalStorage>(),
//         ),
//         permanent: true,
//       );
//       print('📝 RegisterRepository registrado');
//     }
//   }

//   // PASO 4: SERVICES
//   static void _initServices() {
//     if (!Get.isRegistered<AuthService>()) {
//       Get.put<AuthService>(
//         AuthService(localStorage: Get.find<LocalStorage>()),
//         permanent: true,
//       );
//       print('🔧 AuthService registrado');
//     }
//   }

//   // PASO 5: USE CASES (TODOS JUNTOS ANTES DE CONTROLLERS)
//   static void _initUseCases() {
//     print('🎯 Registrando UseCases...');

//     // Login UseCase
//     if (!Get.isRegistered<LoginUseCase>()) {
//       Get.put<LoginUseCase>(
//         LoginUseCase(Get.find<AuthRepository>()),
//         permanent: true,
//       );
//       print('  ✅ LoginUseCase');
//     }

//     // Logout UseCase
//     if (!Get.isRegistered<LogoutUseCase>()) {
//       Get.put<LogoutUseCase>(
//         LogoutUseCase(Get.find<AuthRepository>()),
//         permanent: true,
//       );
//       print('  ✅ LogoutUseCase');
//     }

//     // Register UseCase
//     if (!Get.isRegistered<RegisterUseCase>()) {
//       Get.put<RegisterUseCase>(
//         RegisterUseCase(Get.find<RegisterRepository>()),
//         permanent: true,
//       );
//       print('  ✅ RegisterUseCase');
//     }

//     // Google Sign In UseCase
//     if (!Get.isRegistered<GoogleSignInUseCase>()) {
//       Get.put<GoogleSignInUseCase>(
//         GoogleSignInUseCase(Get.find<GoogleAuthRepository>()),
//         permanent: true,
//       );
//       print('  ✅ GoogleSignInUseCase');
//     }

//     // Request Verification Code UseCase
//     if (!Get.isRegistered<RequestVerificationCodeUseCase>()) {
//       Get.put<RequestVerificationCodeUseCase>(
//         RequestVerificationCodeUseCase(Get.find<AuthRepository>()),
//         permanent: true,
//       );
//       print('  ✅ RequestVerificationCodeUseCase');
//     }

//     // Verify Email UseCase
//     if (!Get.isRegistered<VerifyEmailUseCase>()) {
//       Get.put<VerifyEmailUseCase>(
//         VerifyEmailUseCase(Get.find<AuthRepository>()),
//         permanent: true,
//       );
//       print('  ✅ VerifyEmailUseCase');
//     }

//     // Reset Password UseCase
//     if (!Get.isRegistered<ResetPasswordUseCase>()) {
//       Get.put<ResetPasswordUseCase>(
//         ResetPasswordUseCase(Get.find<AuthRepository>()),
//         permanent: true,
//       );
//       print('  ✅ ResetPasswordUseCase');
//     }
//   }

//   // PASO 6: CONTROLLERS (DESPUÉS DE TODOS LOS USECASES)
//   static void _initControllers() {
//     print('🎮 Registrando Controllers...');

//     // Login Controller
//     if (!Get.isRegistered<LoginController>()) {
//       Get.put<LoginController>(
//         LoginController(loginUseCase: Get.find<LoginUseCase>()),
//         permanent: true,
//       );
//       print('  ✅ LoginController');
//     }

//     // Logout Controller
//     if (!Get.isRegistered<LogoutController>()) {
//       Get.put<LogoutController>(
//         LogoutController(logoutUseCase: Get.find<LogoutUseCase>()),
//         permanent: true,
//       );
//       print('  ✅ LogoutController');
//     }

//     // Register Controller - CON REQUESTVERIFICATIONCODEUSECASE
//     if (!Get.isRegistered<RegisterController>()) {
//       Get.put<RegisterController>(
//         RegisterController(
//           registerUseCase: Get.find<RegisterUseCase>(),
//           requestVerificationCodeUseCase:
//               Get.find<RequestVerificationCodeUseCase>(),
//         ),
//         permanent: true,
//       );
//       print('  ✅ RegisterController (con RequestVerificationCodeUseCase)');
//     }

//     // Google Auth Controller
//     if (!Get.isRegistered<GoogleAuthController>()) {
//       Get.put<GoogleAuthController>(
//         GoogleAuthController(
//             googleSignInUseCase: Get.find<GoogleSignInUseCase>()),
//         permanent: true,
//       );
//       print('  ✅ GoogleAuthController');
//     }

//     // Email Verification Controller
//     // if (!Get.isRegistered<EmailVerificationController>()) {
//     //   Get.put<EmailVerificationController>(
//     //     EmailVerificationController(
//     //       requestCodeUseCase: Get.find<RequestVerificationCodeUseCase>(),
//     //       verifyEmailUseCase: Get.find<VerifyEmailUseCase>(),
//     //     ),
//     //     permanent: true,
//     //   );
//     //   print('  ✅ EmailVerificationController');
//     // }
//   }

//   // MÉTODO DE LIMPIEZA PARA RESET PASSWORD
//   static void cleanupResetPasswordResources() {
//     try {
//       if (Get.isRegistered<ResetPasswordController>()) {
//         final controller = Get.find<ResetPasswordController>();

//         // Liberar controladores de texto
//         try {
//           controller.passwordController.dispose();
//           controller.confirmPasswordController.dispose();
//         } catch (e) {
//           print('Error al liberar controladores de texto: $e');
//         }

//         // Eliminar la instancia
//         Get.delete<ResetPasswordController>(force: true);
//       }
//     } catch (e) {
//       print('Error al limpiar ResetPasswordController: $e');
//     }

//     // Limpiar UseCase
//     try {
//       if (Get.isRegistered<ResetPasswordUseCase>()) {
//         Get.delete<ResetPasswordUseCase>(force: true);
//       }
//     } catch (e) {
//       print('Error al limpiar ResetPasswordUseCase: $e');
//     }

//     // Limpiar Snackbars
//     if (Get.isSnackbarOpen) {
//       Get.closeAllSnackbars();
//     }

//     print('✅ Recursos de restablecimiento de contraseña liberados');
//   }
// }

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
import 'package:login_signup/features/auth/domain/usecases/request_password_reset_usecase.dart';
import 'package:login_signup/features/auth/domain/usecases/reset_password_usecase.dart';
import 'package:login_signup/features/auth/domain/usecases/verify_email_usecase.dart';

import 'package:login_signup/features/auth/presentation/controllers/logout_controller.dart';
import 'package:login_signup/features/auth/presentation/controllers/reset_password_controller.dart';
import 'package:login_signup/shared/local_storage/local_storage.dart';

class AuthModule {
  static Future<void> init() async {
    try {
      print('🔄 Inicializando AuthModule...');

      // PASO 1: CORE DEPENDENCIES
      await _initCoreDependencies();

      // PASO 2: DATA SOURCES
      _initDataSources();

      // PASO 3: REPOSITORIES
      _initRepositories();

      // PASO 4: SERVICES
      _initServices();

      // PASO 5: USE CASES
      _initUseCases();

      // PASO 6: CONTROLLERS
      _initControllers();

      print('✅ AuthModule inicializado correctamente');
    } catch (e) {
      print('❌ Error inicializando AuthModule: $e');
      rethrow;
    }
  }

  // PASO 1: CORE DEPENDENCIES
  static Future<void> _initCoreDependencies() async {
    // Verificar si Dio ya está registrado
    if (!Get.isRegistered<Dio>()) {
      final dio = ApiConfig.createDio(EnvConfig.apiUrl);
      Get.put<Dio>(dio, permanent: true);
      print('📡 Dio registrado');
    }

    // Verificar si LocalStorage ya está registrado
    if (!Get.isRegistered<LocalStorage>()) {
      if (!Get.isRegistered<FlutterSecureStorage>()) {
        Get.put<FlutterSecureStorage>(const FlutterSecureStorage(),
            permanent: true);
        print('🔐 FlutterSecureStorage registrado');
      }
      Get.put<LocalStorage>(LocalStorage(Get.find()), permanent: true);
      print('💾 LocalStorage registrado');
    }
  }

  // PASO 2: DATA SOURCES
  static void _initDataSources() {
    // Auth Remote DataSource
    if (!Get.isRegistered<AuthRemoteDataSource>()) {
      Get.put<AuthRemoteDataSource>(
        AuthRemoteDataSource(
          dio: Get.find<Dio>(),
          localStorage: Get.find<LocalStorage>(),
        ),
        permanent: true,
      );
      print('📡 AuthRemoteDataSource registrado');
    }

    // Google Auth DataSource
    if (!Get.isRegistered<GoogleAuthDataSource>()) {
      Get.put<GoogleAuthDataSource>(
        GoogleAuthDataSourceImpl(
          dio: Get.find<Dio>(),
          localStorage: Get.find<LocalStorage>(),
        ),
        permanent: true,
      );
      print('🌐 GoogleAuthDataSource registrado');
    }
  }

  // PASO 3: REPOSITORIES
  static void _initRepositories() {
    // Auth Repository
    if (!Get.isRegistered<AuthRepository>()) {
      Get.put<AuthRepository>(
        AuthRepositoryImpl(
          remoteDataSource: Get.find<AuthRemoteDataSource>(),
          localStorage: Get.find<LocalStorage>(),
        ),
        permanent: true,
      );
      print('🏛️ AuthRepository registrado');
    }

    // Google Auth Repository
    if (!Get.isRegistered<GoogleAuthRepository>()) {
      Get.put<GoogleAuthRepository>(
        GoogleAuthRepositoryImpl(
          googleAuthDataSource: Get.find<GoogleAuthDataSource>(),
        ),
        permanent: true,
      );
      print('🌐 GoogleAuthRepository registrado');
    }

    // Register Repository
    if (!Get.isRegistered<RegisterRepository>()) {
      Get.put<RegisterRepository>(
        RegisterRepositoryImpl(
          remoteDataSource: Get.find<AuthRemoteDataSource>(),
          localStorage: Get.find<LocalStorage>(),
        ),
        permanent: true,
      );
      print('📝 RegisterRepository registrado');
    }
  }

  // PASO 4: SERVICES
  static void _initServices() {
    if (!Get.isRegistered<AuthService>()) {
      Get.put<AuthService>(
        AuthService(localStorage: Get.find<LocalStorage>()),
        permanent: true,
      );
      print('🔧 AuthService registrado');
    }
  }

  // PASO 5: USE CASES (TODOS JUNTOS ANTES DE CONTROLLERS)
  static void _initUseCases() {
    print('🎯 Registrando UseCases...');

    // Login UseCase
    if (!Get.isRegistered<LoginUseCase>()) {
      Get.put<LoginUseCase>(
        LoginUseCase(Get.find<AuthRepository>()),
        permanent: true,
      );
      print('  ✅ LoginUseCase');
    }

    // Logout UseCase
    if (!Get.isRegistered<LogoutUseCase>()) {
      Get.put<LogoutUseCase>(
        LogoutUseCase(Get.find<AuthRepository>()),
        permanent: true,
      );
      print('  ✅ LogoutUseCase');
    }

    // Register UseCase
    if (!Get.isRegistered<RegisterUseCase>()) {
      Get.put<RegisterUseCase>(
        RegisterUseCase(Get.find<RegisterRepository>()),
        permanent: true,
      );
      print('  ✅ RegisterUseCase');
    }

    // Google Sign In UseCase
    if (!Get.isRegistered<GoogleSignInUseCase>()) {
      Get.put<GoogleSignInUseCase>(
        GoogleSignInUseCase(Get.find<GoogleAuthRepository>()),
        permanent: true,
      );
      print('  ✅ GoogleSignInUseCase');
    }

    // Request Verification Code UseCase
    if (!Get.isRegistered<RequestVerificationCodeUseCase>()) {
      Get.put<RequestVerificationCodeUseCase>(
        RequestVerificationCodeUseCase(Get.find<AuthRepository>()),
        permanent: true,
      );
      print('  ✅ RequestVerificationCodeUseCase');
    }

    // ← NUEVO: Request Password Reset UseCase
    if (!Get.isRegistered<RequestPasswordResetUseCase>()) {
      Get.put<RequestPasswordResetUseCase>(
        RequestPasswordResetUseCase(Get.find<AuthRepository>()),
        permanent: true,
      );
      print('  ✅ RequestPasswordResetUseCase');
    }

    // Verify Email UseCase
    if (!Get.isRegistered<VerifyEmailUseCase>()) {
      Get.put<VerifyEmailUseCase>(
        VerifyEmailUseCase(Get.find<AuthRepository>()),
        permanent: true,
      );
      print('  ✅ VerifyEmailUseCase');
    }

    // Reset Password UseCase
    if (!Get.isRegistered<ResetPasswordUseCase>()) {
      Get.put<ResetPasswordUseCase>(
        ResetPasswordUseCase(Get.find<AuthRepository>()),
        permanent: true,
      );
      print('  ✅ ResetPasswordUseCase');
    }
  }

  // PASO 6: CONTROLLERS (DESPUÉS DE TODOS LOS USECASES)
  /// Solo el `LogoutController`, de alcance de app (lo usan el drawer y la
  /// sesión expirada). Los formularios de auth (`Login`, `Register`,
  /// `ForgotPassword`, `GoogleAuth`) los registran sus bindings de ruta y se
  /// borran al salir de ella: así el formulario no guarda datos de otra sesión.
  static void _initControllers() {
    if (!Get.isRegistered<LogoutController>()) {
      Get.put<LogoutController>(
        LogoutController(logoutUseCase: Get.find<LogoutUseCase>()),
        permanent: true,
      );
    }
  }

  // MÉTODO DE LIMPIEZA PARA RESET PASSWORD
  static void cleanupResetPasswordResources() {
    try {
      if (Get.isRegistered<ResetPasswordController>()) {
        final controller = Get.find<ResetPasswordController>();

        // Liberar controladores de texto
        try {
          controller.passwordController.dispose();
          controller.confirmPasswordController.dispose();
        } catch (e) {
          print('Error al liberar controladores de texto: $e');
        }

        // Eliminar la instancia
        Get.delete<ResetPasswordController>(force: true);
      }
    } catch (e) {
      print('Error al limpiar ResetPasswordController: $e');
    }

    // Limpiar Snackbars
    if (Get.isSnackbarOpen) {
      Get.closeAllSnackbars();
    }

    print('✅ Recursos de restablecimiento de contraseña liberados');
  }

  // ← NUEVO: Método específico para inicializar reset password dinámicamente
  static void initResetPasswordDependencies() {
    print('🔑 Inicializando dependencias de Reset Password...');

    // Asegurar que los use cases estén disponibles
    if (!Get.isRegistered<ResetPasswordUseCase>()) {
      Get.put<ResetPasswordUseCase>(
        ResetPasswordUseCase(Get.find<AuthRepository>()),
        permanent: true,
      );
      print('  ✅ ResetPasswordUseCase registrado dinámicamente');
    }

    if (!Get.isRegistered<RequestPasswordResetUseCase>()) {
      Get.put<RequestPasswordResetUseCase>(
        RequestPasswordResetUseCase(Get.find<AuthRepository>()),
        permanent: true,
      );
      print('  ✅ RequestPasswordResetUseCase registrado dinámicamente');
    }
  }
}
