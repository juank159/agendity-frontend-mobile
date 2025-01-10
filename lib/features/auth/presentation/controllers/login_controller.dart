import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../domain/usecases/login_usecase.dart';

class LoginController extends GetxController {
  final LoginUseCase loginUseCase;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final isLoading = false.obs;

  LoginController({required this.loginUseCase});

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
    if (!validateInput()) return;

    isLoading.value = true;

    final result = await loginUseCase.call(
      email: emailController.text.trim(),
      password: passwordController.text,
    );

    result.fold(
      (failure) {
        _showSnackbar(
          title: 'Error',
          message: failure.message,
          color: Colors.red,
        );
      },
      (user) {
        clearInputs();
        Get.offAllNamed('/home');
      },
    );

    isLoading.value = false;
  }

  void clearInputs() {
    emailController.clear();
    passwordController.clear();
  }

  void _showSnackbar({
    required String title,
    required String message,
    required Color color,
  }) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: color.withOpacity(0.9),
      colorText: Colors.white,
      margin: const EdgeInsets.all(15),
      borderRadius: 8,
      icon: Icon(
        color == Colors.green ? Icons.check_circle : Icons.error,
        color: Colors.white,
      ),
    );
  }
}
