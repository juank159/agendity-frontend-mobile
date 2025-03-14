import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SafeNavigationService {
  static bool _isNavigating = false;

  /// Navega de manera segura a una ruta específica
  static Future<void> navigateTo(String routeName, {dynamic arguments}) async {
    if (_isNavigating) return;

    try {
      _isNavigating = true;

      // Cierra el teclado si está abierto
      FocusManager.instance.primaryFocus?.unfocus();

      // Cierra cualquier SnackBar abierto
      if (Get.isSnackbarOpen) {
        Get.closeAllSnackbars();
      }

      // Espera un breve momento para que se complete cualquier animación pendiente
      await Future.delayed(const Duration(milliseconds: 100));

      // Navega a la ruta especificada
      Get.offNamed(routeName, arguments: arguments);

      // Espera otro momento para asegurar que la navegación terminó
      await Future.delayed(const Duration(milliseconds: 300));
    } catch (e) {
      debugPrint('Error en navegación: $e');
    } finally {
      _isNavigating = false;
    }
  }
}
