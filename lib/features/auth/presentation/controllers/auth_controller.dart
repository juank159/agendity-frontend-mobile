import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';

class AuthController extends GetxController {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final isLoading = false.obs;

  bool validateInput() {
    if (emailController.text.isEmpty || !emailController.text.isEmail) {
      _showSnackbar(
        title: 'Error',
        message: 'Por favor, ingrese un correo válido',
        color: Colors.yellow[800]!,
      );
      return false;
    }
    if (passwordController.text.isEmpty || passwordController.text.length < 6) {
      _showSnackbar(
        title: 'Error',
        message: 'La contraseña debe tener al menos 6 caracteres',
        color: Colors.red,
      );
      return false;
    }
    return true;
  }

  Future<void> loginUser() async {
    final String? baseUrl = dotenv.env['API_URL'];
    if (!validateInput()) return;
    isLoading.value = true;
    try {
      final dio = Dio();
      final response = await dio.post('$baseUrl/auth/login', data: {
        'email': emailController.text.trim(),
        'password': passwordController.text,
      });
      if (response.statusCode == 200) {
        clearInputs();
        Get.offAllNamed('/home');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        _showSnackbar(
          title: 'Error',
          message: 'Correo o contraseña incorrectos',
          color: Colors.red,
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  void clearInputs() {
    emailController.clear();
    passwordController.clear();
  }

  // Método para mostrar el Snackbar personalizado
  void _showSnackbar({
    required String title,
    required String message,
    required Color color,
  }) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: color.withOpacity(0.9), // Color con opacidad
      colorText: Colors.white,
      margin: const EdgeInsets.all(15),
      borderRadius: 8,
      icon: Icon(
        color == Colors.green
            ? Icons.check_circle
            : Icons.error, // Ícono según el tipo de alerta
        color: Colors.white,
      ),
    );
  }
}
