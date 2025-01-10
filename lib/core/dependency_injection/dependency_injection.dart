import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:login_signup/features/auth/data/datasources/register_local_datasource.dart';
import 'package:login_signup/features/auth/data/datasources/register_remote_datasource.dart';
import 'package:login_signup/features/auth/data/repositories/register_repository_impl.dart';
import 'package:login_signup/features/auth/domain/repositories/register_repository.dart';
import 'package:login_signup/features/auth/domain/services/auth_service.dart';
import 'package:login_signup/features/auth/domain/usecases/register_usecase.dart';
import 'package:login_signup/features/auth/presentation/controllers/login_controller.dart';
import 'package:login_signup/features/auth/presentation/controllers/logout_controller.dart';
import 'package:login_signup/features/auth/presentation/controllers/register_controller.dart';
import 'package:login_signup/features/services/data/datasources/services_remote_datasource.dart';
import 'package:login_signup/features/services/data/repositories/services_repository_impl.dart';
import 'package:login_signup/features/services/domain/repositories/services_repository.dart';
import 'package:login_signup/features/services/presentation/controller/services_controller.dart';
import 'package:login_signup/shared/local_storage/local_storage.dart';
import 'package:login_signup/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:login_signup/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:login_signup/features/auth/domain/repositories/auth_repository.dart';
import 'package:login_signup/features/auth/domain/usecases/login_usecase.dart';
import 'package:login_signup/shared/controller/custom_bottom_navigation_controller.dart';

class DependencyInjection {
  static Future<void> init() async {
    try {
      // Cargar variables de entorno
      await dotenv.load(fileName: ".env");

      // External Dependencies
      await _initExternalDependencies();

      // Local Storage
      _initLocalStorage();

      // Auth Dependencies
      _initAuthDependencies();

      // Feature Dependencies
      _initLoginDependencies();
      _initRegisterDependencies();
      _initServicesDependencies();
      _initNavigationDependencies();
    } catch (e) {
      print('Error initializing dependencies: $e');
      rethrow;
    }
  }

  static Future<void> _initExternalDependencies() async {
    final String baseUrl = dotenv.env['API_URL'] ?? '';
    if (baseUrl.isEmpty) {
      throw Exception('API_URL not found in environment variables');
    }

    final dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 3),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ))
      ..interceptors.add(LogInterceptor(
        request: true,
        responseBody: true,
        requestBody: true,
        requestHeader: true,
      ));

    Get.put(dio, permanent: true);
    Get.put(const FlutterSecureStorage(), permanent: true);
  }

  static void _initLocalStorage() {
    try {
      Get.put(
        LocalStorage(Get.find<FlutterSecureStorage>()),
        permanent: true,
      );
    } catch (e) {
      print('Error initializing local storage: $e');
      rethrow;
    }
  }

  static void _initLoginDependencies() {
    // Data Sources
    Get.put(
      AuthRemoteDataSource(Get.find<Dio>()),
      permanent: true,
    );

    // Repositories
    Get.put<AuthRepository>(
      AuthRepositoryImpl(
        remoteDataSource: Get.find<AuthRemoteDataSource>(),
        localStorage: Get.find<LocalStorage>(),
      ),
      permanent: true,
    );

    // Use Cases
    Get.put(
      LoginUseCase(Get.find<AuthRepository>()),
      permanent: true,
    );

    // Controllers
    Get.put(
      LoginController(loginUseCase: Get.find<LoginUseCase>()),
      permanent: true,
    );
  }

  static void _initRegisterDependencies() {
    // Data Sources
    Get.lazyPut<RegisterRemoteDataSource>(
      () => RegisterRemoteDataSourceImpl(dio: Get.find<Dio>()),
    );
    Get.lazyPut<RegisterLocalDataSource>(
      () => RegisterLocalDataSourceImpl(
        storage: Get.find<FlutterSecureStorage>(),
      ),
    );

    // Repositories
    Get.lazyPut<RegisterRepository>(() => RegisterRepositoryImpl(
          remoteDataSource: Get.find<RegisterRemoteDataSource>(),
          localDataSource: Get.find<RegisterLocalDataSource>(),
        ));

    // Use Cases
    Get.lazyPut(() => RegisterUseCase(Get.find<RegisterRepository>()));

    // Controllers
    Get.lazyPut(() => RegisterController(
          registerUseCase: Get.find<RegisterUseCase>(),
        ));
  }

  static void _initServicesDependencies() {
    try {
      // Data Sources
      Get.put(
        ServicesRemoteDataSource(
          dio: Get.find<Dio>(),
          localStorage: Get.find<LocalStorage>(),
        ),
        permanent: true,
      );

      // Repositories
      Get.put<ServicesRepository>(
        ServicesRepositoryImpl(
          remoteDataSource: Get.find<ServicesRemoteDataSource>(),
        ),
        permanent: true,
      );

      // Controllers
      Get.put(
        ServicesController(
          repository: Get.find<ServicesRepository>(),
        ),
        permanent: true,
      );
    } catch (e) {
      print('Error initializing services dependencies: $e');
      rethrow;
    }
  }

  static void _initAuthDependencies() {
    // Auth Service
    Get.put(
      AuthService(localStorage: Get.find<LocalStorage>()),
      permanent: true,
    );

    // Logout Controller
    Get.put(
      LogoutController(authService: Get.find<AuthService>()),
      permanent: true,
    );
  }

  static void _initNavigationDependencies() {
    Get.put(
      CustomBottomNavigationController(),
      permanent: true,
    );
  }
}
