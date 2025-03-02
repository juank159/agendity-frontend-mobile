import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:login_signup/core/di/modules/appointments_module.dart';
import 'package:login_signup/core/di/modules/employees_module.dart';
import 'package:login_signup/core/di/modules/payment_module.dart';
import 'package:login_signup/core/di/modules/statistics_module.dart';
import 'package:login_signup/core/di/modules/user_module.dart';
import 'package:login_signup/core/di/modules/whatsapp_module.dart';
import 'package:login_signup/core/network/network_info.dart';
import 'package:login_signup/shared/local_storage/local_storage.dart';
import '../config/env_config.dart';
import '../config/api_config.dart';
import 'modules/auth_module.dart';
import 'modules/services_module.dart';
import 'modules/categories_module.dart';
import 'modules/navigation_module.dart';
import 'modules/clients_module.dart';

class DependencyInjection {
  static Future<void> init() async {
    try {
      await _initEnv();
      await _initCore();
      await _initFeatures();
      _initNavigation();
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

      final localStorage = LocalStorage(Get.find<FlutterSecureStorage>());
      await localStorage.init();
      Get.put<LocalStorage>(localStorage, permanent: true);

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
      await UserModule.init();
      await ServicesModule.init();
      await CategoriesModule.init();
      await ClientsModule.init();
      await AppointmentsModule.init();
      await EmployeesModule.init();
      await PaymentModule.init();
      await StatisticsModule.init();
      await WhatsappModule.init();

      print('Features initialized successfully');
    } catch (e) {
      print('Error initializing features: $e');
      rethrow;
    }
  }

  static void _initNavigation() {
    try {
      NavigationModule.init();
    } catch (e) {
      print('Error initializing navigation: $e');
      rethrow;
    }
  }
}
