import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NavigationHelper {
  // Método para reiniciar la app después de restablecer la contraseña
  static void restartAppToLogin() {
    // Cerrar todos los snackbars y diálogos abiertos
    if (Get.isSnackbarOpen) {
      Get.closeAllSnackbars();
    }
    if (Get.isDialogOpen ?? false) {
      Get.back();
    }

    // Usar el contexto de la ruta actual para reiniciar la navegación
    final context = Get.context;
    if (context != null) {
      // Limpiar la pila de navegación y reiniciar desde la ruta de inicio de sesión
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    } else {
      // Fallback si no tenemos contexto
      Get.offAllNamed('/login');
    }
  }
}
