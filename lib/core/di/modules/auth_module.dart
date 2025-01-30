import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/config/api_config.dart';
import 'package:login_signup/core/config/env_config.dart';
import 'package:login_signup/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:login_signup/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:login_signup/features/auth/domain/repositories/auth_repository.dart';
import 'package:login_signup/features/auth/domain/services/auth_service.dart';
import 'package:login_signup/features/auth/domain/usecases/login_usecase.dart';
import 'package:login_signup/features/auth/domain/usecases/logout_usecase.dart';
import 'package:login_signup/features/auth/presentation/controllers/login_controller.dart';
import 'package:login_signup/features/auth/presentation/controllers/logout_controller.dart';
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
    } catch (e) {
      print('Error initializing AuthModule: $e');
      rethrow;
    }
  }
}
