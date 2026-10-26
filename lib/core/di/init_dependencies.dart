import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:login_signup/core/di/modules/appointments_module.dart';
import 'package:login_signup/core/di/modules/employees_module.dart';

import 'package:login_signup/core/di/modules/register_module.dart';
import 'package:login_signup/core/di/modules/statistics_module.dart';
import 'package:login_signup/core/di/modules/subscriptions_module.dart';
import 'package:login_signup/core/di/modules/user_module.dart';
import 'package:login_signup/core/network/api_client.dart';
import 'package:login_signup/core/network/network_info.dart';
import 'package:login_signup/core/session/session_repository.dart';
import 'package:login_signup/core/session/session_service.dart';
import 'package:login_signup/core/session/token_store.dart';
import 'package:login_signup/shared/controller/theme_controller.dart';
import 'package:login_signup/shared/local_storage/local_storage.dart';
import '../config/env_config.dart';
import '../config/api_config.dart';
import 'modules/auth_module.dart';
import 'modules/clients_module.dart';
import 'package:login_signup/features/payments/payments_dependencies.dart';
import 'package:login_signup/features/services/services_dependencies.dart';
import 'package:login_signup/features/whatsapp/whatsapp_dependencies.dart';

class DependencyInjection {
  static Future<void> init() async {
    try {
      // Ya no se llama a _initEnv() porque se inicializa antes en main()
      await _initCore();
      await _initFeatures();
      _initThemeController(); // Añadimos la inicialización del controlador de temas
    } catch (e) {
      print('Error initializing dependencies: $e');
      rethrow;
    }
  }

  static Future<void> initAuthDependencies() async {
    try {
      await _initCore();
      await AuthModule.init();
    } catch (e) {
      print('Error initializing auth dependencies: $e');
      rethrow;
    }
  }

  static Future<void> _initEnv() async {
    try {
      await EnvConfig.init();
      EnvConfig.validateEnv();
    } catch (e) {
      print('Error initializing environment: $e');
      rethrow;
    }
  }

  static Future<void> _initCore() async {
    try {
      final dio = ApiConfig.createDio(EnvConfig.apiUrl);
      Get.put<Dio>(dio, permanent: true);
      Get.put<FlutterSecureStorage>(const FlutterSecureStorage(),
          permanent: true);

      // Agregar esta línea para inicializar InternetConnectionChecker
      Get.put<InternetConnectionChecker>(InternetConnectionChecker(),
          permanent: true);

      // Sesión (3.02): TokenStore es el único dueño del token; LocalStorage
      // delega en él. SessionService es la entrada de presentation.
      final tokenStore = SecureTokenStore(Get.find<FlutterSecureStorage>());
      Get.put<TokenStore>(tokenStore, permanent: true);
      Get.put<SessionRepository>(SessionRepository(tokenStore),
          permanent: true);
      Get.put<SessionService>(
        SessionService(
          tokenStore: tokenStore,
          repository: Get.find<SessionRepository>(),
        ),
        permanent: true,
      );

      final localStorage = LocalStorage(Get.find<FlutterSecureStorage>(),
          tokenStore: tokenStore);
      await localStorage.init();
      Get.put<LocalStorage>(localStorage, permanent: true);

      // Dio nuevo (D-04): convive con el de ApiConfig hasta terminar la Fase 4.
      // Solo lo usan las features ya migradas: Get.find<Dio>(tag: apiClientTag).
      // Un 401 con token → SessionService.handleSessionExpired, que borra el
      // token y llama a `SessionService.onSessionExpired` (lo asigna presentation).
      Get.put<Dio>(
        buildApiClient(
          baseUrl: EnvConfig.apiUrl,
          tokenStore: tokenStore,
          onSessionExpired: Get.find<SessionService>().handleSessionExpired,
        ),
        tag: apiClientTag,
        permanent: true,
      );

      // Inicializar NetworkInfo
      Get.put<NetworkInfo>(
        NetworkInfoImpl(connectionChecker: Get.find()),
        permanent: true,
      );

      print('Core dependencies initialized successfully');
    } catch (e) {
      print('Error initializing core dependencies: $e');
      rethrow;
    }
  }

  static Future<void> _initFeatures() async {
    try {
      if (!Get.isRegistered<Dio>()) {
        throw Exception('Core dependencies not initialized');
      }

      await AuthModule.init();
      await RegisterModule.init();
      await UserModule.init();
      ServicesDependencies.init();
      await ClientsModule.init();
      await AppointmentsModule.init();
      await EmployeesModule.init();
      PaymentsDependencies.init();
      await StatisticsModule.init();
      await SubscriptionsModule.init();
      WhatsappDependencies.init();

      print('Features initialized successfully');
    } catch (e) {
      print('Error initializing features: $e');
      rethrow;
    }
  }

  // Añadir este método para inicializar el ThemeController
  static void _initThemeController() {
    try {
      if (!Get.isRegistered<ThemeController>()) {
        Get.put<ThemeController>(ThemeController(), permanent: true);
        print('Theme controller initialized successfully');
      }
    } catch (e) {
      print('Error initializing theme controller: $e');
      rethrow;
    }
  }
}
