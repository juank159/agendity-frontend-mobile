import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/features/auth/domain/usecases/login_usecase.dart';

import '../widgets/custom_dialog.dart';
import '../../../../core/errors/failures.dart';

class LoginController extends GetxController {
  final LoginUseCase _loginUseCase;

  LoginController({required LoginUseCase loginUseCase})
      : _loginUseCase = loginUseCase;

  // Controllers
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  // Observables
  final isLoading = false.obs;
  final isPasswordHidden = true.obs;
  final emailError = RxnString();
  final passwordError = RxnString();

  // Form
  final formKey = GlobalKey<FormState>();

  @override
  void onInit() {
    super.onInit();
    // Limpiamos errores cuando el usuario empiece a escribir
    emailController.addListener(() => emailError.value = null);
    passwordController.addListener(() => passwordError.value = null);
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  void togglePasswordVisibility() {
    isPasswordHidden.value = !isPasswordHidden.value;
  }

  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      emailError.value = 'El correo es requerido';
      return emailError.value;
    }
    if (!GetUtils.isEmail(value)) {
      emailError.value = 'Ingrese un correo válido';
      return emailError.value;
    }
    emailError.value = null;
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      passwordError.value = 'La contraseña es requerida';
      return passwordError.value;
    }
    if (value.length < 6) {
      passwordError.value = 'La contraseña debe tener al menos 6 caracteres';
      return passwordError.value;
    }
    passwordError.value = null;
    return null;
  }

  Future<void> loginUser() async {
    // Validar el formulario
    if (!formKey.currentState!.validate()) {
      _showErrorDialog('Por favor, complete todos los campos correctamente');
      return;
    }

    try {
      isLoading.value = true;

      final result = await _loginUseCase(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      result.fold(
        (failure) => _handleFailure(failure),
        (user) => _handleSuccess(),
      );
    } catch (e) {
      _showErrorDialog('Error inesperado: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  void _handleFailure(Failure failure) {
    String errorMessage = _mapFailureToMessage(failure);
    _showErrorDialog(errorMessage);
  }

  void _handleSuccess() {
    clearInputs();
    Get.offAllNamed('/home');
  }

  String _mapFailureToMessage(Failure failure) {
    if (failure is ServerFailure) {
      if (failure.message.contains('401')) {
        return 'Credenciales incorrectas. Por favor, verifica tu correo y contraseña';
      }
      if (failure.message.contains('404')) {
        return 'Usuario no encontrado. ¿Estás registrado?';
      }
      if (failure.message.contains('429')) {
        return 'Demasiados intentos. Por favor, espera unos minutos';
      }
      if (failure.message.contains('500')) {
        return 'Error en el servidor. Por favor, inténtalo más tarde';
      }
      return 'Error de conexión. Verifica tu conexión a internet';
    }
    return 'Error inesperado. Por favor, inténtalo de nuevo';
  }

  void _showErrorDialog(String message) {
    CustomDialog.show(
      title: 'Error de inicio de sesión',
      message: message,
      type: DialogType.error,
    );
  }

  void clearInputs() {
    emailController.clear();
    passwordController.clear();
    emailError.value = null;
    passwordError.value = null;
  }

  // Método para pruebas y depuración
  bool isValidEmail(String email) => GetUtils.isEmail(email);
  bool isValidPassword(String password) => password.length >= 6;
}
