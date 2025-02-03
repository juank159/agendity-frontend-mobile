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

  Future<void> logout() async {
    try {
      isLoading.value = true;

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
            await _cleanupModules();
            Get.deleteAll(force: true);
            await Get.offAllNamed('/login');
            await DependencyInjection.initAuthDependencies();
            _showSuccessMessage();
          } catch (e) {
            _showErrorMessage('Error al reiniciar la aplicación');
          }
        },
      );
    } catch (e) {
      _showErrorMessage('Error al cerrar sesión');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _cleanupModules() async {
    if (Get.isRegistered<ServicesController>()) {
      Get.find<ServicesController>().clearServices();
    }
    ServicesModule.reset();
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
