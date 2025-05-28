// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:login_signup/features/auth/domain/usecases/login_usecase.dart';

// class LoginController extends GetxController {
//   final LoginUseCase loginUseCase;

//   // Cambiamos esto para usar UniqueKey en vez de GlobalKey
//   final formKey = UniqueKey();

//   // Controllers
//   final emailController = TextEditingController();
//   final passwordController = TextEditingController();

//   // Observables
//   final isLoading = false.obs;
//   final isPasswordHidden = true.obs;
//   final emailError = Rx<String?>(null);
//   final passwordError = Rx<String?>(null);

//   LoginController({required this.loginUseCase});

//   @override
//   void onClose() {
//     // Cleanup controllers
//     emailController.dispose();
//     passwordController.dispose();
//     super.onClose();
//   }

//   void togglePasswordVisibility() {
//     isPasswordHidden.value = !isPasswordHidden.value;
//   }

//   String? validateEmail(String? value) {
//     if (value == null || value.isEmpty) {
//       emailError.value = 'Por favor, ingrese su correo electrónico';
//       return emailError.value;
//     }
//     if (!GetUtils.isEmail(value)) {
//       emailError.value = 'Por favor, ingrese un correo válido';
//       return emailError.value;
//     }
//     emailError.value = null;
//     return null;
//   }

//   String? validatePassword(String? value) {
//     if (value == null || value.isEmpty) {
//       passwordError.value = 'Por favor, ingrese su contraseña';
//       return passwordError.value;
//     }
//     if (value.length < 6) {
//       passwordError.value = 'La contraseña debe tener al menos 6 caracteres';
//       return passwordError.value;
//     }
//     passwordError.value = null;
//     return null;
//   }

//   Future<void> loginUser() async {
//     // Limpiar errores previos
//     emailError.value = null;
//     passwordError.value = null;

//     // Validar campos
//     final emailValid = validateEmail(emailController.text) == null;
//     final passwordValid = validatePassword(passwordController.text) == null;

//     if (!emailValid || !passwordValid) {
//       return;
//     }

//     isLoading.value = true;

//     try {
//       final result = await loginUseCase(
//         email: emailController.text.trim(),
//         password: passwordController.text,
//       );

//       result.fold(
//         (failure) {
//           isLoading.value = false;
//           Get.snackbar(
//             'Error',
//             failure.message,
//             snackPosition: SnackPosition.TOP,
//             backgroundColor: Colors.red.withOpacity(0.9),
//             colorText: Colors.white,
//             margin: const EdgeInsets.all(15),
//             borderRadius: 8,
//           );
//         },
//         (user) {
//           isLoading.value = false;
//           Get.offAllNamed('/');
//         },
//       );
//     } catch (e) {
//       isLoading.value = false;
//       Get.snackbar(
//         'Error',
//         'Ha ocurrido un error inesperado',
//         snackPosition: SnackPosition.TOP,
//         backgroundColor: Colors.red.withOpacity(0.9),
//         colorText: Colors.white,
//         margin: const EdgeInsets.all(15),
//         borderRadius: 8,
//       );
//     }
//   }
// }

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/errors/failures.dart'; // Importa la clase Failure
import 'package:login_signup/features/auth/domain/usecases/login_usecase.dart';

class LoginController extends GetxController {
  final LoginUseCase loginUseCase;

  // Cambiamos esto para usar UniqueKey en vez de GlobalKey
  final formKey = UniqueKey();

  // Controllers
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  // Observables
  final isLoading = false.obs;
  final isPasswordHidden = true.obs;
  final emailError = Rx<String?>(null);
  final passwordError = Rx<String?>(null);

  LoginController({required this.loginUseCase});

  @override
  void onClose() {
    // Cleanup controllers
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  void togglePasswordVisibility() {
    isPasswordHidden.value = !isPasswordHidden.value;
  }

  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      emailError.value = 'Por favor, ingrese su correo electrónico';
      return emailError.value;
    }
    if (!GetUtils.isEmail(value)) {
      emailError.value = 'Por favor, ingrese un correo válido';
      return emailError.value;
    }
    emailError.value = null;
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      passwordError.value = 'Por favor, ingrese su contraseña';
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
    // Limpiar errores previos
    emailError.value = null;
    passwordError.value = null;

    // Validar campos
    final emailValidationMessage = validateEmail(emailController.text);
    final passwordValidationMessage = validatePassword(passwordController.text);

    if (emailValidationMessage != null || passwordValidationMessage != null) {
      return;
    }

    isLoading.value = true;

    try {
      final result = await loginUseCase(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      result.fold(
        (failure) {
          print(
              'LoginController: Falla en fold. Tipo: ${failure.runtimeType}, Mensaje: ${failure.message}'); // Debug
          isLoading.value = false;
          Get.snackbar(
            'Error',
            failure
                .message, // Aquí se mostrará el mensaje específico de la falla
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.red.withOpacity(0.9),
            colorText: Colors.white,
            margin: const EdgeInsets.all(15),
            borderRadius: 8,
          );
        },
        (user) {
          print('LoginController: Login exitoso en fold.'); // Debug
          isLoading.value = false;
          Get.offAllNamed('/');
        },
      );
    } catch (e) {
      print(
          'LoginController: Capturada excepción en catch general: ${e.runtimeType} - ${e.toString()}'); // Debug
      isLoading.value = false;
      String errorMessage = 'Ha ocurrido un error inesperado.';
      if (e is Failure) {
        // Si la excepción es una de tus clases Failure
        errorMessage = e.message; // Usa el mensaje de la Failure
      } else {
        // Para cualquier otra excepción no controlada
        errorMessage =
            'Ha ocurrido un error inesperado. Por favor, inténtelo de nuevo.';
        print(
            'Error inesperado no manejado: $e'); // Imprime el error completo para depuración
      }

      Get.snackbar(
        'Error',
        errorMessage,
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.withOpacity(0.9),
        colorText: Colors.white,
        margin: const EdgeInsets.all(15),
        borderRadius: 8,
      );
    }
  }
}
