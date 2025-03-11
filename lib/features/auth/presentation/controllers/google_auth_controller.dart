// lib/features/auth/presentation/controllers/google_auth_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/routes/routes.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/features/auth/domain/usecases/google_sign_in_usecase.dart';

class GoogleAuthController extends GetxController {
  final GoogleSignInUseCase googleSignInUseCase;

  // Estado observable
  final isLoading = false.obs;
  final errorMessage = RxnString();

  GoogleAuthController({required this.googleSignInUseCase});

  Future<void> signInWithGoogle() async {
    try {
      isLoading.value = true;
      errorMessage.value = null;

      final result = await googleSignInUseCase(NoParams());

      result.fold(
        (failure) {
          errorMessage.value = failure.message;
          _showSnackbar(
            title: 'Error',
            message: failure.message,
            color: Colors.red,
          );
        },
        (user) {
          // Navegamos a la pantalla principal después del inicio de sesión exitoso
          Get.offAllNamed(GetRoutes.home);
        },
      );
    } catch (e) {
      errorMessage.value = e.toString();
      _showSnackbar(
        title: 'Error',
        message: 'Error inesperado: ${e.toString()}',
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
