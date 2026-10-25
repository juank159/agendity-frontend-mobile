import 'package:login_signup/core/routes/routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/features/auth/domain/usecases/login_usecase.dart';
import 'package:login_signup/shared/controller/session_controller.dart';

class LoginController extends GetxController {
  final LoginUseCase loginUseCase;

  // Form key corregido
  final formKey = GlobalKey<FormState>();

  // Controllers
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  // Observables para estado
  final isLoading = false.obs;
  final isPasswordHidden = true.obs;

  // Observables para errores (corregidos para trabajar con la vista mejorada)
  final emailError = ''.obs;
  final passwordError = ''.obs;

  LoginController({required this.loginUseCase});

  @override
  void onInit() {
    super.onInit();

    // Mostrar mensaje si viene desde verificación de email
    if (Get.arguments != null && Get.arguments['message'] != null) {
      Future.delayed(const Duration(milliseconds: 500), () {
        final messageType = Get.arguments['messageType'] ?? 'info';
        _showSnackbar(
          title: messageType == 'success' ? 'Éxito' : 'Información',
          message: Get.arguments['message'],
          color: messageType == 'success' ? Colors.green : Colors.blue,
        );
      });
    }
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

  // Validación de email actualizada
  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      emailError.value = 'Por favor, ingrese su correo electrónico';
      return emailError.value;
    }
    if (!GetUtils.isEmail(value)) {
      emailError.value = 'Por favor, ingrese un correo válido';
      return emailError.value;
    }
    emailError.value = '';
    return null;
  }

  // Validación de contraseña actualizada
  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      passwordError.value = 'Por favor, ingrese su contraseña';
      return passwordError.value;
    }
    if (value.length < 6) {
      passwordError.value = 'La contraseña debe tener al menos 6 caracteres';
      return passwordError.value;
    }
    passwordError.value = '';
    return null;
  }

  // Validación completa mejorada
  bool _validateAllFields() {
    bool isValid = true;

    // Limpiar errores previos
    emailError.value = '';
    passwordError.value = '';

    // Validar email
    final email = emailController.text.trim();
    if (email.isEmpty) {
      emailError.value = 'El correo electrónico es obligatorio';
      isValid = false;
    } else if (!email.isEmail) {
      emailError.value = 'Ingrese un correo electrónico válido';
      isValid = false;
    }

    // Validar contraseña
    final password = passwordController.text;
    if (password.isEmpty) {
      passwordError.value = 'La contraseña es obligatoria';
      isValid = false;
    } else if (password.length < 6) {
      passwordError.value = 'La contraseña debe tener al menos 6 caracteres';
      isValid = false;
    }

    return isValid;
  }

  Future<void> loginUser() async {
    print('🔑 Iniciando proceso de login...');

    // Validar campos primero
    if (!_validateAllFields()) {
      _showSnackbar(
        title: 'Error de validación',
        message: 'Por favor, corrija los errores antes de continuar',
        color: Colors.red,
      );
      return;
    }

    print('✅ Validación exitosa, procediendo con login...');
    isLoading.value = true;

    try {
      final result = await loginUseCase(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      result.fold(
        (failure) {
          print('❌ Error en login: ${failure.message}');
          isLoading.value = false;

          // Manejar errores específicos
          String errorMessage = failure.message;
          if (errorMessage.toLowerCase().contains('credenciales')) {
            emailError.value = 'Credenciales incorrectas';
            passwordError.value = 'Credenciales incorrectas';
          } else if (errorMessage.toLowerCase().contains('email') ||
              errorMessage.toLowerCase().contains('correo')) {
            emailError.value = 'Correo electrónico no encontrado';
          } else if (errorMessage.toLowerCase().contains('password') ||
              errorMessage.toLowerCase().contains('contraseña')) {
            passwordError.value = 'Contraseña incorrecta';
          }

          _showSnackbar(
            title: 'Error de inicio de sesión',
            message: failure.message,
            color: Colors.red,
          );
        },
        (user) {
          print('✅ Login exitoso para usuario: ${user.name}');
          isLoading.value = false;


          // Mensaje de bienvenida mejorado
          _showSnackbar(
            title: '¡Bienvenido!',
            message: 'Hola ${user.name}, has iniciado sesión correctamente.',
            color: Colors.green,
            duration: const Duration(seconds: 2),
          );

          // Limpiar campos después del login exitoso
          _clearFields();

          // La capa de datos ya guardó el token: se carga la sesión de la UI
          // antes de navegar (AuthMiddleware la exige en la home).
          _enterHome();
        },
      );
    } catch (e) {
      print('❌ Error inesperado en login: ${e.toString()}');
      isLoading.value = false;

      String errorMessage = 'Ha ocurrido un error inesperado.';
      if (e is Failure) {
        errorMessage = e.message;
      } else {
        errorMessage =
            'Ha ocurrido un error inesperado. Por favor, inténtelo de nuevo.';
        print('Error inesperado no manejado: $e');
      }

      _showSnackbar(
        title: 'Error inesperado',
        message: errorMessage,
        color: Colors.red,
      );
    }
  }

  // Método para limpiar campos
  void _clearFields() {
    emailController.clear();
    passwordController.clear();
    emailError.value = '';
    passwordError.value = '';
  }

  // Método centralizado para mostrar snackbars
  void _showSnackbar({
    required String title,
    required String message,
    required Color color,
    Duration duration = const Duration(seconds: 4),
  }) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: color.withValues(alpha: 0.9),
      colorText: Colors.white,
      margin: const EdgeInsets.all(15),
      borderRadius: 12,
      duration: duration,
      icon: Icon(
        color == Colors.green
            ? Icons.check_circle
            : color == Colors.blue
                ? Icons.info
                : Icons.error,
        color: Colors.white,
      ),
      animationDuration: const Duration(milliseconds: 500),
    );
  }

  // Método helper para limpiar errores manualmente si es necesario
  void clearErrors() {
    emailError.value = '';
    passwordError.value = '';
  }

  // Método para verificar si hay errores
  bool get hasErrors =>
      emailError.value.isNotEmpty || passwordError.value.isNotEmpty;

  Future<void> _enterHome() async {
    final sessionFuture = Get.find<SessionController>().reload();
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (await sessionFuture == null) {
      _showSnackbar(
        title: 'Error de inicio de sesión',
        message: 'No se pudo iniciar la sesión. Inténtalo de nuevo.',
        color: Colors.red,
      );
      return;
    }
    Get.offAllNamed(GetRoutes.home);
  }
}
