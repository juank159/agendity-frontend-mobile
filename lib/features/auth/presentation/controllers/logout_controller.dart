import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../domain/services/auth_service.dart';

class LogoutController extends GetxController {
  final AuthService _authService;

  LogoutController({required AuthService authService})
      : _authService = authService;

  Future<void> logout() async {
    try {
      await _authService.signOut();
      await Get.offAllNamed('/login'); // Asegúrate de que esta ruta exista
      _showSuccessMessage();
    } catch (e) {
      _showErrorMessage(e.toString());
    }
  }

  void _showSuccessMessage() {
    Get.snackbar(
      'Éxito',
      'Sesión cerrada correctamente',
      backgroundColor: const Color(0xFF4CAF50),
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
      snackPosition: SnackPosition.TOP,
    );
  }

  void _showErrorMessage(String error) {
    Get.snackbar(
      'Error',
      'No se pudo cerrar la sesión',
      backgroundColor: const Color(0xFFD32F2F),
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
      snackPosition: SnackPosition.TOP,
    );
  }
}
