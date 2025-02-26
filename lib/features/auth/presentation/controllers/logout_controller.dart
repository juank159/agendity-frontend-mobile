// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:login_signup/features/services/presentation/controller/services_controller.dart';
// import '../../domain/usecases/logout_usecase.dart';
// import '../../../../core/di/init_dependencies.dart';
// import '../../../../core/di/modules/services_module.dart';
// import '../../../../shared/controller/custom_bottom_navigation_controller.dart';

// class LogoutController extends GetxController {
//   final LogoutUseCase _logoutUseCase;
//   final RxBool isLoading = false.obs;

//   LogoutController({required LogoutUseCase logoutUseCase})
//       : _logoutUseCase = logoutUseCase;

//   Future<void> logout() async {
//     try {
//       isLoading.value = true;

//       if (Get.isRegistered<CustomBottomNavigationController>()) {
//         Get.find<CustomBottomNavigationController>().reset();
//       }

//       final result = await _logoutUseCase.execute();

//       result.fold(
//         (failure) {
//           _showErrorMessage(failure.message);
//         },
//         (_) async {
//           try {
//             await _cleanupModules();
//             Get.deleteAll(force: true);
//             await Get.offAllNamed('/login');
//             await DependencyInjection.initAuthDependencies();
//             _showSuccessMessage();
//           } catch (e) {
//             _showErrorMessage('Error al reiniciar la aplicación');
//           }
//         },
//       );
//     } catch (e) {
//       _showErrorMessage('Error al cerrar sesión');
//     } finally {
//       isLoading.value = false;
//     }
//   }

//   Future<void> _cleanupModules() async {
//     if (Get.isRegistered<ServicesController>()) {
//       Get.find<ServicesController>().clearServices();
//     }
//     ServicesModule.reset();
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
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/di/modules/clients_module.dart';
import 'package:login_signup/core/di/modules/employees_module.dart';
import 'package:login_signup/features/services/presentation/controller/services_controller.dart';
import 'package:login_signup/features/appointments/presentation/controllers/appointments_controller.dart';
import 'package:login_signup/features/employees/presentation/controllers/employees_controller.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../../../core/di/init_dependencies.dart';
import '../../../../core/di/modules/services_module.dart';
import '../../../../shared/controller/custom_bottom_navigation_controller.dart';

class LogoutController extends GetxController {
  final LogoutUseCase _logoutUseCase;
  final RxBool isLoading = false.obs;

  LogoutController({required LogoutUseCase logoutUseCase})
      : _logoutUseCase = logoutUseCase;

  Future<void> logout() async {
    try {
      isLoading.value = true;

      // Resetear el controlador de navegación primero
      if (Get.isRegistered<CustomBottomNavigationController>()) {
        Get.find<CustomBottomNavigationController>().reset();
      }

      final result = await _logoutUseCase.execute();

      result.fold(
        (failure) {
          _showErrorMessage(failure.message);
        },
        (_) async {
          try {
            // Limpieza ordenada y completa
            await _cleanupDependencies();

            // Navegación y reinicio
            await Get.offAllNamed('/login');
            await DependencyInjection.initAuthDependencies();
            _showSuccessMessage();
          } catch (e) {
            print('Error durante la limpieza: $e');
            _showErrorMessage('Error al reiniciar la aplicación');
          }
        },
      );
    } catch (e) {
      print('Error en logout: $e');
      _showErrorMessage('Error al cerrar sesión');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _cleanupDependencies() async {
    // Eliminar los controladores en orden inverso a su dependencia
    final controllers = [
      'AppointmentsController',
      'ServicesController',
      'EmployeesController',
      'UserInfoController',
      'CustomBottomNavigationController'
    ];

    for (final controller in controllers) {
      try {
        if (Get.isRegistered(tag: controller)) {
          Get.delete(tag: controller, force: true);
          print('Controller eliminado: $controller');
        }
      } catch (e) {
        print('Error al eliminar $controller: $e');
      }
    }

    // Limpiar los módulos
    if (Get.isRegistered<ServicesController>()) {
      Get.find<ServicesController>().clearServices();
    }
    ServicesModule.reset();
    ClientsModule.reset();
    EmployeesModule.reset();

    // Eliminar todas las demás dependencias
    Get.deleteAll(force: true);
  }

  Future<void> _cleanupControllers() async {
    // 1. Eliminar controladores dependientes primero
    if (Get.isRegistered<AppointmentsController>()) {
      try {
        Get.delete<AppointmentsController>(force: true);
      } catch (e) {
        print('Error al eliminar AppointmentsController: $e');
      }
    }

    // 2. Luego eliminar controladores de servicios
    if (Get.isRegistered<ServicesController>()) {
      try {
        Get.find<ServicesController>().clearServices();
        Get.delete<ServicesController>(force: true);
      } catch (e) {
        print('Error al eliminar ServicesController: $e');
      }
    }

    // 3. Finalmente eliminar controladores base
    if (Get.isRegistered<EmployeesController>()) {
      try {
        Get.delete<EmployeesController>(force: true);
      } catch (e) {
        print('Error al eliminar EmployeesController: $e');
      }
    }
  }

  Future<void> _cleanupModules() async {
    try {
      ServicesModule.reset();
      // Aquí puedes agregar la limpieza de otros módulos
    } catch (e) {
      print('Error al limpiar módulos: $e');
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
    );
  }
}
