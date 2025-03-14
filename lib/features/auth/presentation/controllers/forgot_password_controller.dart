import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/features/auth/domain/usecases/request_password_reset_usecase.dart';

class ForgotPasswordController extends GetxController {
  final RequestPasswordResetUseCase requestPasswordResetUseCase;

  final emailController = TextEditingController();
  final isLoading = false.obs;

  ForgotPasswordController({required this.requestPasswordResetUseCase});

  @override
  void onClose() {
    emailController.dispose();
    super.onClose();
  }

  Future<void> requestPasswordReset() async {
    if (emailController.text.isEmpty ||
        !GetUtils.isEmail(emailController.text)) {
      _showSnackbar(
        title: 'Error',
        message: 'Por favor, ingrese un correo electrónico válido',
        color: Colors.red,
      );
      return;
    }

    isLoading.value = true;

    try {
      final result = await requestPasswordResetUseCase(
        email: emailController.text.trim(),
      );

      result.fold(
        (failure) {
          _showSnackbar(
            title: 'Error',
            message: failure.message,
            color: Colors.red,
          );
        },
        (success) {
          _showSnackbar(
            title: 'Éxito',
            message: 'Se ha enviado un código de recuperación a tu correo',
            color: Colors.green,
          );
          // Navegar a la pantalla de recuperación de contraseña
          Get.toNamed('/reset-password',
              arguments: {'email': emailController.text.trim()});
        },
      );
    } catch (e) {
      _showSnackbar(
        title: 'Error',
        message: e.toString(),
        color: Colors.red,
      );
    } finally {
      isLoading.value = false;
    }
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
      duration: const Duration(seconds: 6),
      icon: Icon(
        color == Colors.green ? Icons.check_circle : Icons.error,
        color: Colors.white,
      ),
    );
  }
}
