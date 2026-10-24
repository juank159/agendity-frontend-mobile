import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/di/modules/clients_module.dart';
import 'package:login_signup/core/di/modules/employees_module.dart';
import 'package:login_signup/core/di/modules/services_module.dart';
import 'package:login_signup/core/routes/routes.dart';
import 'package:login_signup/features/services/presentation/controller/services_controller.dart';
import 'package:login_signup/shared/controller/session_controller.dart';
import '../../domain/usecases/logout_usecase.dart';

/// Cierre de sesión: manual (drawer) o por sesión vencida (401 del Dio 'api').
class LogoutController extends GetxController {
  final LogoutUseCase _logoutUseCase;
  final RxBool isLoading = false.obs;
  bool _ending = false;

  LogoutController({required LogoutUseCase logoutUseCase})
      : _logoutUseCase = logoutUseCase;

  /// Logout pedido por el usuario.
  Future<void> logout() => endSession();

  /// Cierra la sesión, limpia los datos de las features y lleva al login.
  /// Con [expired] muestra "Tu sesión expiró" en vez del mensaje de logout.
  Future<void> endSession({bool expired = false}) async {
    if (_ending) return;
    _ending = true;
    try {
      isLoading.value = true;

      // 1. Sesión (token + estado en memoria) por SessionService.
      if (Get.isRegistered<SessionController>()) {
        await Get.find<SessionController>().end();
      }

      // 2. Resto de datos locales (LocalStorage.clearAllData).
      final result = await _logoutUseCase.execute();
      result.fold(
        (failure) => debugPrint('Logout: limpieza local con error: '
            '${failure.message}'),
        (_) {},
      );

      // 3. Datos de las features (se preserva auth).
      _cleanupFeatureModules();

      await Get.offAllNamed(GetRoutes.login);
      if (expired) {
        _showMessage('Sesión expirada',
            'Tu sesión expiró. Inicia sesión de nuevo.', Colors.orange);
      } else {
        _showMessage('Éxito', 'Sesión cerrada correctamente', Colors.green);
      }
    } catch (e) {
      debugPrint('Error en logout: $e');
      _showMessage('Error', 'Error al cerrar sesión', Colors.red);
    } finally {
      isLoading.value = false;
      _ending = false;
    }
  }

  void _cleanupFeatureModules() {
    try {
      if (Get.isRegistered<ServicesController>()) {
        Get.find<ServicesController>().clearServices();
      }
      ServicesModule.reset();
      ClientsModule.reset();
      EmployeesModule.reset();
    } catch (e) {
      debugPrint('Error al limpiar módulos de funcionalidades: $e');
    }
  }

  void _showMessage(String title, String message, Color color) {
    Get.snackbar(
      title,
      message,
      backgroundColor: color,
      colorText: Colors.white,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 3),
      borderRadius: 8,
      margin: const EdgeInsets.all(8),
    );
  }
}
