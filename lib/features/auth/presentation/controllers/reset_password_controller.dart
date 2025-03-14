import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/features/auth/domain/usecases/reset_password_usecase.dart';

class ResetPasswordController extends GetxController {
  final ResetPasswordUseCase resetPasswordUseCase;

  // Observables
  final email = ''.obs;
  final code = ''.obs;
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final isLoading = false.obs;
  final isSuccess = false.obs;

  // Para la visibilidad de las contraseñas
  final isPasswordHidden = true.obs;
  final isConfirmPasswordHidden = true.obs;

  // Para el temporizador
  final timeRemaining = 600.obs; // 10 minutos
  final isTimerActive = false.obs;
  Timer? _timer;

  ResetPasswordController({required this.resetPasswordUseCase});

  @override
  void onInit() {
    super.onInit();
    if (Get.arguments != null && Get.arguments['email'] != null) {
      email.value = Get.arguments['email'];
      // Iniciar el temporizador al llegar a la pantalla
      _startTimer();
    }
  }

  @override
  void onClose() {
    // Cancelar el temporizador
    _timer?.cancel();

    // Solo liberamos los controladores si no estamos en proceso de navegación exitosa
    if (!isSuccess.value) {
      try {
        passwordController.dispose();
        confirmPasswordController.dispose();
      } catch (e) {
        print('Error al liberar controladores: $e');
      }
    }
    super.onClose();
  }

  // Método para cambiar la visibilidad de la contraseña
  void togglePasswordVisibility() {
    isPasswordHidden.value = !isPasswordHidden.value;
  }

  // Método para cambiar la visibilidad de la confirmación de contraseña
  void toggleConfirmPasswordVisibility() {
    isConfirmPasswordHidden.value = !isConfirmPasswordHidden.value;
  }

  // Método para iniciar el temporizador
  void _startTimer() {
    _timer?.cancel();
    timeRemaining.value = 600; // 10 minutos
    isTimerActive.value = true;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (timeRemaining.value > 0) {
        timeRemaining.value--;
      } else {
        timer.cancel();
        isTimerActive.value = false;
        Get.snackbar(
          'Aviso',
          'El código ha expirado, solicita uno nuevo',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
        );
      }
    });
  }

  // Método para formatear el tiempo restante
  String get formattedTime {
    final minutes = (timeRemaining.value / 60).floor();
    final seconds = timeRemaining.value % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // Método para solicitar un nuevo código
  Future<void> requestNewCode() async {
    if (isLoading.value) return;

    isLoading.value = true;

    try {
      // Puedes implementar la llamada a tu API para solicitar un nuevo código
      // Como ejemplo, simulamos una respuesta exitosa
      await Future.delayed(const Duration(seconds: 1));

      _startTimer();

      Get.snackbar(
        'Código enviado',
        'Se ha enviado un nuevo código de recuperación a tu correo',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error al solicitar nuevo código: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> resetPassword() async {
    if (isLoading.value) return;

    // Validaciones básicas
    if (code.value.isEmpty || code.value.length < 6) {
      Get.snackbar(
        'Error',
        'Por favor, ingrese el código de recuperación completo',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    if (passwordController.text.isEmpty || passwordController.text.length < 6) {
      Get.snackbar(
        'Error',
        'La contraseña debe tener al menos 6 caracteres',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      Get.snackbar(
        'Error',
        'Las contraseñas no coinciden',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    isLoading.value = true;

    try {
      final result = await resetPasswordUseCase(
        email: email.value,
        code: code.value,
        newPassword: passwordController.text,
      );

      result.fold(
        (failure) {
          isLoading.value = false;
          Get.snackbar(
            'Error',
            failure.message,
            backgroundColor: Colors.red,
            colorText: Colors.white,
            snackPosition: SnackPosition.TOP,
          );
        },
        (success) {
          isLoading.value = false;
          isSuccess.value = true; // Marcar como exitoso antes de navegar

          Get.snackbar(
            'Éxito',
            'Contraseña actualizada correctamente',
            backgroundColor: Colors.green,
            colorText: Colors.white,
            snackPosition: SnackPosition.TOP,
            duration: const Duration(seconds: 2),
          );

          // Navegación después de un breve delay
          Future.delayed(const Duration(milliseconds: 2000), () {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              // Limpiar cualquier estado residual
              if (Get.isSnackbarOpen) {
                Get.closeAllSnackbars();
              }

              try {
                // Eliminar todas las rutas
                Get.until((route) => false);
                // Navegar al login
                Get.offAllNamed('/login');
              } catch (e) {
                print('Error en navegación: $e');
                // Plan B
                Get.offAll(
                    () => const Scaffold(
                        body: Center(child: CircularProgressIndicator())),
                    duration: const Duration(milliseconds: 100),
                    transition: Transition.fade);
                Future.delayed(const Duration(milliseconds: 100), () {
                  Get.offAllNamed('/login');
                });
              }
            });
          });
        },
      );
    } catch (e) {
      print('Error al restablecer contraseña: $e');
      isLoading.value = false;
      Get.snackbar(
        'Error',
        'Error inesperado. Por favor, intenta de nuevo',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    }
  }
}
