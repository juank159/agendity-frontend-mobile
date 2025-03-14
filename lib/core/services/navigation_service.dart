import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NavigationService {
  /// Navega al login después del restablecimiento de contraseña
  /// Utiliza un enfoque a prueba de fallos para garantizar una navegación exitosa
  static void safeNavigateToLogin() {
    // Suspende cualquier procesamiento por un breve momento
    Future.delayed(const Duration(milliseconds: 300), () {
      try {
        // Método principal: navegación directa a través del contexto raíz
        if (Get.key.currentContext != null) {
          Navigator.of(Get.key.currentContext!, rootNavigator: true)
              .pushNamedAndRemoveUntil('/login', (_) => false);
          return;
        }

        // Plan B: Usa la navegación GetX con offAll
        Get.offAllNamed('/login');
      } catch (e) {
        print('Error en navegación: $e');

        // Plan C: Reiniciar la app como último recurso
        try {
          Get.reset();
          Get.to(() => const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              ));

          // Delay corto y luego navegar al login
          Future.delayed(const Duration(milliseconds: 500), () {
            Get.offAllNamed('/login');
          });
        } catch (e) {
          print('Error al reiniciar navegación: $e');
        }
      }
    });
  }
}
