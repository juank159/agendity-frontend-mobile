import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

import 'package:login_signup/core/network/api_client.dart';
import 'package:login_signup/core/network/network_info.dart';
import 'package:login_signup/core/session/session_repository.dart';
import 'package:login_signup/core/session/session_service.dart';
import 'package:login_signup/core/session/token_store.dart';
import 'package:login_signup/shared/controllers/theme_controller.dart';
import 'package:login_signup/shared/local_storage/local_storage.dart';
import '../config/env_config.dart';
import 'package:login_signup/features/appointments/appointments_dependencies.dart';
import 'package:login_signup/features/auth/auth_dependencies.dart';
import 'package:login_signup/features/auth/presentation/bindings/session_binding.dart';
import 'package:login_signup/features/clients/clients_dependencies.dart';
import 'package:login_signup/features/employees/employees_dependencies.dart';
import 'package:login_signup/features/payments/payments_dependencies.dart';
import 'package:login_signup/features/statistics/statistics_dependencies.dart';
import 'package:login_signup/features/subscriptions/subscriptions_dependencies.dart';
import 'package:login_signup/features/services/services_dependencies.dart';
import 'package:login_signup/features/whatsapp/whatsapp_dependencies.dart';
import 'package:login_signup/core/utils/app_logger.dart';

class DependencyInjection {
  static Future<void> init() async {
    try {
      // EnvConfig se inicializa antes, en main().
      await _initCore();
      await _initFeatures();
      _initThemeController(); // Añadimos la inicialización del controlador de temas
    } catch (e) {
      AppLogger.error('Error initializing dependencies', e);
      rethrow;
    }
  }

  static Future<void> _initCore() async {
    try {
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

      // Único Dio de la app (5.01): Get.find<Dio>(tag: apiClientTag).
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

      AppLogger.debug('Core dependencies initialized successfully');
    } catch (e) {
      AppLogger.error('Error initializing core dependencies', e);
      rethrow;
    }
  }

  static Future<void> _initFeatures() async {
    try {
      if (!Get.isRegistered<Dio>(tag: apiClientTag)) {
        throw Exception('Core dependencies not initialized');
      }

      AuthDependencies.init();
      SessionBinding.register();
      ServicesDependencies.init();
      ClientsDependencies.init();
      AppointmentsDependencies.init();
      EmployeesDependencies.init();
      PaymentsDependencies.init();
      StatisticsDependencies.init();
      SubscriptionsDependencies.init();
      WhatsappDependencies.init();

      AppLogger.debug('Features initialized successfully');
    } catch (e) {
      AppLogger.error('Error initializing features', e);
      rethrow;
    }
  }

  // Añadir este método para inicializar el ThemeController
  static void _initThemeController() {
    try {
      if (!Get.isRegistered<ThemeController>()) {
        Get.put<ThemeController>(ThemeController(), permanent: true);
        AppLogger.debug('Theme controller initialized successfully');
      }
    } catch (e) {
      AppLogger.error('Error initializing theme controller', e);
      rethrow;
    }
  }
}
