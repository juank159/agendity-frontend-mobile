// import 'package:dio/dio.dart';
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// import 'package:get/get.dart';
// import 'package:login_signup/core/di/modules/user_module.dart';
// import 'package:login_signup/shared/local_storage/local_storage.dart';
// import '../config/env_config.dart';
// import '../config/api_config.dart';
// import 'modules/auth_module.dart';
// import 'modules/services_module.dart';
// import 'modules/categories_module.dart';
// import 'modules/navigation_module.dart';

// class DependencyInjection {
//   static Future<void> init() async {
//     try {
//       await _initEnv();
//       await _initCore();
//       await _initFeatures();
//       _initNavigation();
//     } catch (e) {
//       print('Error initializing dependencies: $e');
//       rethrow;
//     }
//   }

//   static Future<void> initAuthDependencies() async {
//     try {
//       // Inicializar solo las dependencias necesarias para auth
//       await _initCore(); // Para reiniciar Dio y FlutterSecureStorage
//       await AuthModule
//           .init(); // Para reiniciar las dependencias de autenticación
//     } catch (e) {
//       print('Error initializing auth dependencies: $e');
//       rethrow;
//     }
//   }

//   static Future<void> _initEnv() async {
//     try {
//       await EnvConfig.init();
//       EnvConfig.validateEnv();
//     } catch (e) {
//       print('Error initializing environment: $e');
//       rethrow;
//     }
//   }

//   static Future<void> _initCore() async {
//     try {
//       final dio = ApiConfig.createDio(EnvConfig.apiUrl);
//       Get.put<Dio>(dio, permanent: true);
//       Get.put<FlutterSecureStorage>(const FlutterSecureStorage(),
//           permanent: true);
//       Get.put<LocalStorage>(LocalStorage(Get.find()), permanent: true);
//     } catch (e) {
//       print('Error initializing core dependencies: $e');
//       rethrow;
//     }
//   }

//   static Future<void> _initFeatures() async {
//     try {
//       if (!Get.isRegistered<Dio>()) {
//         throw Exception('Core dependencies not initialized');
//       }

//       await AuthModule.init();
//       await UserModule.init();

//       // Inicializar módulos que dependen entre sí en orden
//       await ServicesModule.init();
//       await CategoriesModule
//           .init(); // Asegurarse que se inicialice después de Services

//       print('Features initialized successfully');
//     } catch (e) {
//       print('Error initializing features: $e');
//       rethrow;
//     }
//   }

//   static void _initNavigation() {
//     try {
//       NavigationModule.init();
//     } catch (e) {
//       print('Error initializing navigation: $e');
//       rethrow;
//     }
//   }
// }

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/di/modules/user_module.dart';
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
      Get.put<LocalStorage>(LocalStorage(Get.find()), permanent: true);
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
