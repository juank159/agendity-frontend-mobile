// // lib/features/auth/presentation/controllers/logout_controller.dart
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import '../../domain/usecases/logout_usecase.dart';
// import '../../../../core/di/init_dependencies.dart';
// import '../../../../shared/controller/custom_bottom_navigation_controller.dart';

// class LogoutController extends GetxController {
//   final LogoutUseCase _logoutUseCase;
//   final RxBool isLoading = false.obs;

//   LogoutController({required LogoutUseCase logoutUseCase})
//       : _logoutUseCase = logoutUseCase;

//   @override
//   void onInit() {
//     super.onInit();
//     print('LogoutController: Inicializado');
//   }

//   @override
//   void onClose() {
//     print('LogoutController: Cerrando controlador');
//     super.onClose();
//   }

//   Future<void> logout() async {
//     try {
//       print('LogoutController: Iniciando proceso de logout...');
//       isLoading.value = true;

//       // Verificar si hay un token antes del logout
//       if (Get.isRegistered<CustomBottomNavigationController>()) {
//         print('LogoutController: Reseteando navegación...');
//         Get.find<CustomBottomNavigationController>().reset();
//       }

//       final result = await _logoutUseCase.execute();

//       result.fold(
//         (failure) {
//           print('LogoutController: Error en logout - ${failure.message}');
//           _showErrorMessage(failure.message);
//         },
//         (_) async {
//           print('LogoutController: Logout exitoso, limpiando estado...');

//           try {
//             // Limpiar todas las dependencias
//             Get.deleteAll(force: true);
//             print('LogoutController: Dependencias eliminadas');

//             // Navegamos al login
//             await Get.offAllNamed('/login');
//             print('LogoutController: Navegación a login completada');

//             // Reinicializar solo las dependencias necesarias
//             await DependencyInjection.initAuthDependencies();
//             print('LogoutController: Dependencias básicas reinicializadas');

//             _showSuccessMessage();
//             print(
//                 'LogoutController: Proceso de logout completado exitosamente');
//           } catch (e) {
//             print('LogoutController: Error en reinicialización - $e');
//             _showErrorMessage('Error al reiniciar la aplicación');
//           }
//         },
//       );
//     } catch (e) {
//       print('LogoutController: Error inesperado - $e');
//       _showErrorMessage('Error inesperado al cerrar sesión');
//     } finally {
//       isLoading.value = false;
//       print('LogoutController: Estado de carga reiniciado');
//     }
//   }

//   void _showSuccessMessage() {
//     Get.snackbar(
//       'Éxito',
//       'Sesión cerrada correctamente',
//       backgroundColor: Colors.green,
//       colorText: Colors.white,
//       snackPosition: SnackPosition.TOP,
//       duration: const Duration(seconds: 2),
//       borderRadius: 8,
//       margin: const EdgeInsets.all(8),
//       isDismissible: true,
//       dismissDirection: DismissDirection.horizontal,
//       forwardAnimationCurve: Curves.easeOutBack,
//     );
//   }

//   void _showErrorMessage(String error) {
//     Get.snackbar(
//       'Error',
//       error,
//       backgroundColor: Colors.red,
//       colorText: Colors.white,
//       snackPosition: SnackPosition.TOP,
//       duration: const Duration(seconds: 3),
//       borderRadius: 8,
//       margin: const EdgeInsets.all(8),
//       isDismissible: true,
//       dismissDirection: DismissDirection.horizontal,
//       forwardAnimationCurve: Curves.easeOutBack,
//     );
//   }
// }

// lib/features/auth/presentation/controllers/logout_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/features/services/presentation/controller/services_controller.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../../../core/di/init_dependencies.dart';
import '../../../../core/di/modules/services_module.dart';
import '../../../../shared/controller/custom_bottom_navigation_controller.dart';

class LogoutController extends GetxController {
  final LogoutUseCase _logoutUseCase;
  final RxBool isLoading = false.obs;

  LogoutController({required LogoutUseCase logoutUseCase})
      : _logoutUseCase = logoutUseCase;

  @override
  void onInit() {
    super.onInit();
    print('LogoutController: Inicializado');
  }

  @override
  void onClose() {
    print('LogoutController: Cerrando controlador');
    super.onClose();
  }

  Future<void> logout() async {
    try {
      print('LogoutController: Iniciando proceso de logout...');
      isLoading.value = true;

      // Verificar si hay un token antes del logout
      if (Get.isRegistered<CustomBottomNavigationController>()) {
        print('LogoutController: Reseteando navegación...');
        Get.find<CustomBottomNavigationController>().reset();
      }

      final result = await _logoutUseCase.execute();

      result.fold(
        (failure) {
          print('LogoutController: Error en logout - ${failure.message}');
          _showErrorMessage(failure.message);
        },
        (_) async {
          print('LogoutController: Logout exitoso, limpiando estado...');

          try {
            // Primero limpiamos módulos específicos
            await _cleanupModules();
            print('LogoutController: Módulos específicos limpiados');

            // Limpiar todas las dependencias generales
            Get.deleteAll(force: true);
            print('LogoutController: Dependencias generales eliminadas');

            // Navegamos al login
            await Get.offAllNamed('/login');
            print('LogoutController: Navegación a login completada');

            // Reinicializar solo las dependencias necesarias
            await DependencyInjection.initAuthDependencies();
            print('LogoutController: Dependencias básicas reinicializadas');

            _showSuccessMessage();
            print(
                'LogoutController: Proceso de logout completado exitosamente');
          } catch (e) {
            print('LogoutController: Error en reinicialización - $e');
            _showErrorMessage('Error al reiniciar la aplicación');
          }
        },
      );
    } catch (e) {
      print('LogoutController: Error inesperado - $e');
      _showErrorMessage('Error inesperado al cerrar sesión');
    } finally {
      isLoading.value = false;
      print('LogoutController: Estado de carga reiniciado');
    }
  }

  Future<void> _cleanupModules() async {
    try {
      // Limpieza de módulos específicos
      if (Get.isRegistered<ServicesController>()) {
        Get.find<ServicesController>().clearServices();
      }

      // Resetear módulo de servicios
      ServicesModule.reset();

      // Aquí puedes agregar la limpieza de otros módulos específicos
    } catch (e) {
      print('LogoutController: Error en limpieza de módulos - $e');
    }
  }

  void _showSuccessMessage() {
    Get.snackbar(
      'Éxito',
      'Sesión cerrada correctamente',
      backgroundColor: Colors.green,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 2),
      borderRadius: 8,
      margin: const EdgeInsets.all(8),
      isDismissible: true,
      dismissDirection: DismissDirection.horizontal,
      forwardAnimationCurve: Curves.easeOutBack,
    );
  }

  void _showErrorMessage(String error) {
    Get.snackbar(
      'Error',
      error,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 3),
      borderRadius: 8,
      margin: const EdgeInsets.all(8),
      isDismissible: true,
      dismissDirection: DismissDirection.horizontal,
      forwardAnimationCurve: Curves.easeOutBack,
    );
  }
}
