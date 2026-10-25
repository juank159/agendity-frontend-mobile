import 'package:login_signup/core/routes/routes.dart';
// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:login_signup/features/auth/domain/usecases/reset_password_usecase.dart';

// class ResetPasswordController extends GetxController {
//   final ResetPasswordUseCase resetPasswordUseCase;

//   // Observables
//   final email = ''.obs;
//   final code = ''.obs;
//   final passwordController = TextEditingController();
//   final confirmPasswordController = TextEditingController();
//   final isLoading = false.obs;
//   final isSuccess = false.obs;

//   // Para la visibilidad de las contraseñas
//   final isPasswordHidden = true.obs;
//   final isConfirmPasswordHidden = true.obs;

//   // Para el temporizador
//   final timeRemaining = 600.obs; // 10 minutos
//   final isTimerActive = false.obs;
//   Timer? _timer;

//   ResetPasswordController({required this.resetPasswordUseCase});

//   @override
//   void onInit() {
//     super.onInit();
//     if (Get.arguments != null && Get.arguments['email'] != null) {
//       email.value = Get.arguments['email'];
//       // Iniciar el temporizador al llegar a la pantalla
//       _startTimer();
//     }
//   }

//   @override
//   void onClose() {
//     // Cancelar el temporizador
//     _timer?.cancel();

//     // Solo liberamos los controladores si no estamos en proceso de navegación exitosa
//     if (!isSuccess.value) {
//       try {
//         passwordController.dispose();
//         confirmPasswordController.dispose();
//       } catch (e) {
//         print('Error al liberar controladores: $e');
//       }
//     }
//     super.onClose();
//   }

//   // Método para cambiar la visibilidad de la contraseña
//   void togglePasswordVisibility() {
//     isPasswordHidden.value = !isPasswordHidden.value;
//   }

//   // Método para cambiar la visibilidad de la confirmación de contraseña
//   void toggleConfirmPasswordVisibility() {
//     isConfirmPasswordHidden.value = !isConfirmPasswordHidden.value;
//   }

//   // Método para iniciar el temporizador
//   void _startTimer() {
//     _timer?.cancel();
//     timeRemaining.value = 600; // 10 minutos
//     isTimerActive.value = true;

//     _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
//       if (timeRemaining.value > 0) {
//         timeRemaining.value--;
//       } else {
//         timer.cancel();
//         isTimerActive.value = false;
//         Get.snackbar(
//           'Aviso',
//           'El código ha expirado, solicita uno nuevo',
//           backgroundColor: Colors.orange,
//           colorText: Colors.white,
//           snackPosition: SnackPosition.TOP,
//         );
//       }
//     });
//   }

//   // Método para formatear el tiempo restante
//   String get formattedTime {
//     final minutes = (timeRemaining.value / 60).floor();
//     final seconds = timeRemaining.value % 60;
//     return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
//   }

//   // Método para solicitar un nuevo código
//   Future<void> requestNewCode() async {
//     if (isLoading.value) return;

//     isLoading.value = true;

//     try {
//       // Puedes implementar la llamada a tu API para solicitar un nuevo código
//       // Como ejemplo, simulamos una respuesta exitosa
//       await Future.delayed(const Duration(seconds: 1));

//       _startTimer();

//       Get.snackbar(
//         'Código enviado',
//         'Se ha enviado un nuevo código de recuperación a tu correo',
//         backgroundColor: Colors.green,
//         colorText: Colors.white,
//         snackPosition: SnackPosition.TOP,
//       );
//     } catch (e) {
//       Get.snackbar(
//         'Error',
//         'Error al solicitar nuevo código: $e',
//         backgroundColor: Colors.red,
//         colorText: Colors.white,
//         snackPosition: SnackPosition.TOP,
//       );
//     } finally {
//       isLoading.value = false;
//     }
//   }

//   Future<void> resetPassword() async {
//     if (isLoading.value) return;

//     // Validaciones básicas
//     if (code.value.isEmpty || code.value.length < 6) {
//       Get.snackbar(
//         'Error',
//         'Por favor, ingrese el código de recuperación completo',
//         backgroundColor: Colors.red,
//         colorText: Colors.white,
//         snackPosition: SnackPosition.TOP,
//       );
//       return;
//     }

//     if (passwordController.text.isEmpty || passwordController.text.length < 6) {
//       Get.snackbar(
//         'Error',
//         'La contraseña debe tener al menos 6 caracteres',
//         backgroundColor: Colors.red,
//         colorText: Colors.white,
//         snackPosition: SnackPosition.TOP,
//       );
//       return;
//     }

//     if (passwordController.text != confirmPasswordController.text) {
//       Get.snackbar(
//         'Error',
//         'Las contraseñas no coinciden',
//         backgroundColor: Colors.red,
//         colorText: Colors.white,
//         snackPosition: SnackPosition.TOP,
//       );
//       return;
//     }

//     isLoading.value = true;

//     try {
//       final result = await resetPasswordUseCase(
//         email: email.value,
//         code: code.value,
//         newPassword: passwordController.text,
//       );

//       result.fold(
//         (failure) {
//           isLoading.value = false;
//           Get.snackbar(
//             'Error',
//             failure.message,
//             backgroundColor: Colors.red,
//             colorText: Colors.white,
//             snackPosition: SnackPosition.TOP,
//           );
//         },
//         (success) {
//           isLoading.value = false;
//           isSuccess.value = true; // Marcar como exitoso antes de navegar

//           Get.snackbar(
//             'Éxito',
//             'Contraseña actualizada correctamente',
//             backgroundColor: Colors.green,
//             colorText: Colors.white,
//             snackPosition: SnackPosition.TOP,
//             duration: const Duration(seconds: 2),
//           );

//           // Navegación después de un breve delay
//           Future.delayed(const Duration(milliseconds: 2000), () {
//             WidgetsBinding.instance.addPostFrameCallback((_) {
//               // Limpiar cualquier estado residual
//               if (Get.isSnackbarOpen) {
//                 Get.closeAllSnackbars();
//               }

//               try {
//                 // Eliminar todas las rutas
//                 Get.until((route) => false);
//                 // Navegar al login
//                 Get.offAllNamed('/login');
//               } catch (e) {
//                 print('Error en navegación: $e');
//                 // Plan B
//                 Get.offAll(
//                     () => const Scaffold(
//                         body: Center(child: CircularProgressIndicator())),
//                     duration: const Duration(milliseconds: 100),
//                     transition: Transition.fade);
//                 Future.delayed(const Duration(milliseconds: 100), () {
//                   Get.offAllNamed('/login');
//                 });
//               }
//             });
//           });
//         },
//       );
//     } catch (e) {
//       print('Error al restablecer contraseña: $e');
//       isLoading.value = false;
//       Get.snackbar(
//         'Error',
//         'Error inesperado. Por favor, intenta de nuevo',
//         backgroundColor: Colors.red,
//         colorText: Colors.white,
//         snackPosition: SnackPosition.TOP,
//       );
//     }
//   }
// }

// ===============================

// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:login_signup/features/auth/domain/usecases/reset_password_usecase.dart';

// class ResetPasswordController extends GetxController {
//   final ResetPasswordUseCase resetPasswordUseCase;

//   // Observables
//   final email = ''.obs;
//   final code = ''.obs;
//   final passwordController = TextEditingController();
//   final confirmPasswordController = TextEditingController();
//   final isLoading = false.obs;
//   final isSuccess = false.obs;

//   // Para la visibilidad de las contraseñas
//   final isPasswordHidden = true.obs;
//   final isConfirmPasswordHidden = true.obs;

//   // Validaciones de contraseña (igual que register)
//   final passwordValidations = <String, bool>{}.obs;
//   final passwordError = ''.obs;
//   final confirmPasswordError = ''.obs;

//   // Para el temporizador
//   final timeRemaining = 600.obs; // 10 minutos
//   final isTimerActive = false.obs;
//   Timer? _timer;

//   ResetPasswordController({
//     required this.resetPasswordUseCase,
//   });

//   @override
//   void onInit() {
//     super.onInit();
//     if (Get.arguments != null && Get.arguments['email'] != null) {
//       email.value = Get.arguments['email'];
//       // Iniciar el temporizador al llegar a la pantalla
//       _startTimer();
//     }
//   }

//   @override
//   void onClose() {
//     // Cancelar el temporizador
//     _timer?.cancel();

//     // Solo liberamos los controladores si no estamos en proceso de navegación exitosa
//     if (!isSuccess.value) {
//       try {
//         passwordController.dispose();
//         confirmPasswordController.dispose();
//       } catch (e) {
//         debugPrint('Error al liberar controladores: $e');
//       }
//     }
//     super.onClose();
//   }

//   // Métodos para cambiar visibilidad de contraseñas
//   void togglePasswordVisibility() {
//     isPasswordHidden.value = !isPasswordHidden.value;
//   }

//   void toggleConfirmPasswordVisibility() {
//     isConfirmPasswordHidden.value = !isConfirmPasswordHidden.value;
//   }

//   // Validar contraseña con indicadores visuales (igual que register)
//   void validatePassword() {
//     final password = passwordController.text;

//     passwordValidations.value = {
//       'length': password.length >= 8,
//       'uppercase': password.contains(RegExp(r'[A-Z]')),
//       'lowercase': password.contains(RegExp(r'[a-z]')),
//       'number': password.contains(RegExp(r'[0-9]')),
//       'special': password.contains(RegExp(r'[@$!%*?&]')),
//     };

//     // Limpiar error si la contraseña es válida
//     if (passwordValidations.values.every((isValid) => isValid)) {
//       passwordError.value = '';
//     }
//   }

//   // Iconos y colores para validación (igual que register)
//   IconData getValidationIcon(bool isValid) {
//     return isValid ? Icons.check_circle : Icons.cancel;
//   }

//   Color getValidationColor(bool isValid) {
//     return isValid ? Colors.green : Colors.red;
//   }

//   // Validaciones privadas
//   bool _validatePassword() {
//     final password = passwordController.text;

//     if (password.isEmpty) {
//       passwordError.value = 'La contraseña es obligatoria';
//       return false;
//     }

//     // Validar todos los requisitos de seguridad
//     final validations = {
//       'length': password.length >= 8,
//       'uppercase': password.contains(RegExp(r'[A-Z]')),
//       'lowercase': password.contains(RegExp(r'[a-z]')),
//       'number': password.contains(RegExp(r'[0-9]')),
//       'special': password.contains(RegExp(r'[@$!%*?&]')),
//     };

//     passwordValidations.value = validations;

//     if (!validations.values.every((isValid) => isValid)) {
//       passwordError.value =
//           'La contraseña debe cumplir con todos los requisitos de seguridad';
//       return false;
//     }

//     passwordError.value = '';
//     return true;
//   }

//   bool _validateConfirmPassword() {
//     final password = passwordController.text;
//     final confirmPassword = confirmPasswordController.text;

//     if (confirmPassword.isEmpty) {
//       confirmPasswordError.value = 'Debe confirmar su contraseña';
//       return false;
//     }

//     if (password != confirmPassword) {
//       confirmPasswordError.value = 'Las contraseñas no coinciden';
//       return false;
//     }

//     confirmPasswordError.value = '';
//     return true;
//   }

//   // Método para iniciar el temporizador
//   void _startTimer() {
//     _timer?.cancel();
//     timeRemaining.value = 600; // 10 minutos
//     isTimerActive.value = true;

//     _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
//       if (timeRemaining.value > 0) {
//         timeRemaining.value--;
//       } else {
//         timer.cancel();
//         isTimerActive.value = false;
//         _showSnackbar(
//           title: 'Código expirado',
//           message: 'El código ha expirado. Puede solicitar uno nuevo.',
//           color: Colors.orange,
//         );
//       }
//     });
//   }

//   // Método para formatear el tiempo restante
//   String get formattedTime {
//     final minutes = (timeRemaining.value / 60).floor();
//     final seconds = timeRemaining.value % 60;
//     return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
//   }

//   // Verificar si se puede reenviar código
//   bool get canResendCode => !isTimerActive.value && !isLoading.value;

//   // Método para solicitar un nuevo código
//   Future<void> requestNewCode() async {
//     if (isLoading.value || isTimerActive.value) return;

//     isLoading.value = true;

//     try {
//       final result = await resetPasswordUseCase(email: email.value);

//       result.fold(
//         (failure) {
//           _showSnackbar(
//             title: 'Error',
//             message: failure.message,
//             color: Colors.red,
//           );
//         },
//         (success) {
//           _startTimer(); // Reiniciar temporizador
//           _showSnackbar(
//             title: 'Código enviado',
//             message:
//                 'Se ha enviado un nuevo código de recuperación a tu correo',
//             color: Colors.green,
//           );
//         },
//       );
//     } catch (e) {
//       _showSnackbar(
//         title: 'Error',
//         message: 'Error al solicitar nuevo código: $e',
//         color: Colors.red,
//       );
//     } finally {
//       isLoading.value = false;
//     }
//   }

//   Future<void> resetPassword() async {
//     if (isLoading.value) return;

//     // Validaciones básicas
//     if (code.value.isEmpty || code.value.length < 6) {
//       _showSnackbar(
//         title: 'Error',
//         message: 'Por favor, ingrese el código de recuperación completo',
//         color: Colors.red,
//       );
//       return;
//     }

//     // Validar contraseña segura
//     if (!_validatePassword()) {
//       _showSnackbar(
//         title: 'Error de validación',
//         message: 'La contraseña no cumple con los requisitos de seguridad',
//         color: Colors.red,
//       );
//       return;
//     }

//     // Validar confirmación de contraseña
//     if (!_validateConfirmPassword()) {
//       _showSnackbar(
//         title: 'Error de validación',
//         message: confirmPasswordError.value,
//         color: Colors.red,
//       );
//       return;
//     }

//     isLoading.value = true;

//     try {
//       final result = await resetPasswordUseCase(
//         email: email.value,
//         code: code.value,
//         newPassword: passwordController.text,
//       );

//       result.fold(
//         (failure) {
//           isLoading.value = false;
//           _showSnackbar(
//             title: 'Error',
//             message: failure.message,
//             color: Colors.red,
//           );
//         },
//         (success) {
//           isLoading.value = false;
//           isSuccess.value = true;

//           _showSnackbar(
//             title: 'Éxito',
//             message: 'Contraseña actualizada correctamente',
//             color: Colors.green,
//             duration: const Duration(seconds: 2),
//           );

//           // Navegación después de un breve delay
//           Future.delayed(const Duration(milliseconds: 2000), () {
//             WidgetsBinding.instance.addPostFrameCallback((_) {
//               if (Get.isSnackbarOpen) {
//                 Get.closeAllSnackbars();
//               }

//               try {
//                 Get.until((route) => false);
//                 Get.offAllNamed('/login');
//               } catch (e) {
//                 debugPrint('Error en navegación: $e');
//                 Get.offAll(
//                   () => const Scaffold(
//                     body: Center(child: CircularProgressIndicator()),
//                   ),
//                   duration: const Duration(milliseconds: 100),
//                   transition: Transition.fade,
//                 );
//                 Future.delayed(const Duration(milliseconds: 100), () {
//                   Get.offAllNamed('/login');
//                 });
//               }
//             });
//           });
//         },
//       );
//     } catch (e) {
//       debugPrint('Error al restablecer contraseña: $e');
//       isLoading.value = false;
//       _showSnackbar(
//         title: 'Error',
//         message: 'Error inesperado. Por favor, intenta de nuevo',
//         color: Colors.red,
//       );
//     }
//   }

//   void _showSnackbar({
//     required String title,
//     required String message,
//     required Color color,
//     Duration duration = const Duration(seconds: 3),
//   }) {
//     Get.snackbar(
//       title,
//       message,
//       snackPosition: SnackPosition.TOP,
//       backgroundColor: color.withOpacity(0.9),
//       colorText: Colors.white,
//       margin: const EdgeInsets.all(15),
//       borderRadius: 8,
//       duration: duration,
//       icon: Icon(
//         color == Colors.green
//             ? Icons.check_circle
//             : color == Colors.orange
//                 ? Icons.warning
//                 : Icons.error,
//         color: Colors.white,
//       ),
//     );
//   }
// }

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/features/auth/domain/usecases/reset_password_usecase.dart';
import 'package:login_signup/features/auth/domain/usecases/request_password_reset_usecase.dart';

class ResetPasswordController extends GetxController {
  final ResetPasswordUseCase resetPasswordUseCase;
  final RequestPasswordResetUseCase requestPasswordResetUseCase;

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

  // Validaciones de contraseña (igual que register)
  final passwordValidations = <String, bool>{}.obs;
  final passwordError = ''.obs;
  final confirmPasswordError = ''.obs;

  // Para el temporizador
  final timeRemaining = 600.obs; // 10 minutos
  final isTimerActive = false.obs;
  Timer? _timer;

  ResetPasswordController({
    required this.resetPasswordUseCase,
    required this.requestPasswordResetUseCase,
  });

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
        debugPrint('Error al liberar controladores: $e');
      }
    }
    super.onClose();
  }

  // Métodos para cambiar visibilidad de contraseñas
  void togglePasswordVisibility() {
    isPasswordHidden.value = !isPasswordHidden.value;
  }

  void toggleConfirmPasswordVisibility() {
    isConfirmPasswordHidden.value = !isConfirmPasswordHidden.value;
  }

  // Validar contraseña con indicadores visuales (igual que register)
  void validatePassword() {
    final password = passwordController.text;

    passwordValidations.value = {
      'length': password.length >= 8,
      'uppercase': password.contains(RegExp(r'[A-Z]')),
      'lowercase': password.contains(RegExp(r'[a-z]')),
      'number': password.contains(RegExp(r'[0-9]')),
      'special': password.contains(RegExp(r'[@$!%*?&]')),
    };

    // Limpiar error si la contraseña es válida
    if (passwordValidations.values.every((isValid) => isValid)) {
      passwordError.value = '';
    }
  }

  // Iconos y colores para validación (igual que register)
  IconData getValidationIcon(bool isValid) {
    return isValid ? Icons.check_circle : Icons.cancel;
  }

  Color getValidationColor(bool isValid) {
    return isValid ? Colors.green : Colors.red;
  }

  // Validaciones privadas
  bool _validatePassword() {
    final password = passwordController.text;

    if (password.isEmpty) {
      passwordError.value = 'La contraseña es obligatoria';
      return false;
    }

    // Validar todos los requisitos de seguridad
    final validations = {
      'length': password.length >= 8,
      'uppercase': password.contains(RegExp(r'[A-Z]')),
      'lowercase': password.contains(RegExp(r'[a-z]')),
      'number': password.contains(RegExp(r'[0-9]')),
      'special': password.contains(RegExp(r'[@$!%*?&]')),
    };

    passwordValidations.value = validations;

    if (!validations.values.every((isValid) => isValid)) {
      passwordError.value =
          'La contraseña debe cumplir con todos los requisitos de seguridad';
      return false;
    }

    passwordError.value = '';
    return true;
  }

  bool _validateConfirmPassword() {
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;

    if (confirmPassword.isEmpty) {
      confirmPasswordError.value = 'Debe confirmar su contraseña';
      return false;
    }

    if (password != confirmPassword) {
      confirmPasswordError.value = 'Las contraseñas no coinciden';
      return false;
    }

    confirmPasswordError.value = '';
    return true;
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
        _showSnackbar(
          title: 'Código expirado',
          message: 'El código ha expirado. Puede solicitar uno nuevo.',
          color: Colors.orange,
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

  // Verificar si se puede reenviar código
  bool get canResendCode => !isTimerActive.value && !isLoading.value;

  // Método para solicitar un nuevo código (CORREGIDO)
  Future<void> requestNewCode() async {
    if (isLoading.value || isTimerActive.value) return;

    isLoading.value = true;

    try {
      // ✅ USAR RequestPasswordResetUseCase para reenviar código
      final result = await requestPasswordResetUseCase(email: email.value);

      result.fold(
        (failure) {
          _showSnackbar(
            title: 'Error',
            message: failure.message,
            color: Colors.red,
          );
        },
        (_) {
          // ← void, no bool
          _startTimer(); // Reiniciar temporizador
          _showSnackbar(
            title: 'Código enviado',
            message:
                'Se ha enviado un nuevo código de recuperación a tu correo',
            color: Colors.green,
          );
        },
      );
    } catch (e) {
      _showSnackbar(
        title: 'Error',
        message: 'Error al solicitar nuevo código: $e',
        color: Colors.red,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Método para restablecer contraseña (CORREGIDO)
  Future<void> resetPassword() async {
    if (isLoading.value) return;

    // Validaciones básicas
    if (code.value.isEmpty || code.value.length < 6) {
      _showSnackbar(
        title: 'Error',
        message: 'Por favor, ingrese el código de recuperación completo',
        color: Colors.red,
      );
      return;
    }

    // Validar contraseña segura
    if (!_validatePassword()) {
      _showSnackbar(
        title: 'Error de validación',
        message: 'La contraseña no cumple con los requisitos de seguridad',
        color: Colors.red,
      );
      return;
    }

    // Validar confirmación de contraseña
    if (!_validateConfirmPassword()) {
      _showSnackbar(
        title: 'Error de validación',
        message: confirmPasswordError.value,
        color: Colors.red,
      );
      return;
    }

    isLoading.value = true;

    try {
      // ✅ USAR ResetPasswordUseCase para cambiar contraseña
      final result = await resetPasswordUseCase(
        email: email.value,
        code: code.value,
        newPassword: passwordController.text,
      );

      result.fold(
        (failure) {
          isLoading.value = false;
          _showSnackbar(
            title: 'Error',
            message: failure.message,
            color: Colors.red,
          );
        },
        (success) {
          // ← bool
          isLoading.value = false;
          isSuccess.value = true;

          _showSnackbar(
            title: 'Éxito',
            message: 'Contraseña actualizada correctamente',
            color: Colors.green,
            duration: const Duration(seconds: 2),
          );

          // Navegación después de un breve delay
          Future.delayed(const Duration(milliseconds: 2000), () {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (Get.isSnackbarOpen) {
                Get.closeAllSnackbars();
              }

              try {
                Get.until((route) => false);
                Get.offAllNamed(GetRoutes.login);
              } catch (e) {
                debugPrint('Error en navegación: $e');
                Get.offAll(
                  () => const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  ),
                  duration: const Duration(milliseconds: 100),
                  transition: Transition.fade,
                );
                Future.delayed(const Duration(milliseconds: 100), () {
                  Get.offAllNamed(GetRoutes.login);
                });
              }
            });
          });
        },
      );
    } catch (e) {
      debugPrint('Error al restablecer contraseña: $e');
      isLoading.value = false;
      _showSnackbar(
        title: 'Error',
        message: 'Error inesperado. Por favor, intenta de nuevo',
        color: Colors.red,
      );
    }
  }

  void _showSnackbar({
    required String title,
    required String message,
    required Color color,
    Duration duration = const Duration(seconds: 3),
  }) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: color.withValues(alpha: 0.9),
      colorText: Colors.white,
      margin: const EdgeInsets.all(15),
      borderRadius: 8,
      duration: duration,
      icon: Icon(
        color == Colors.green
            ? Icons.check_circle
            : color == Colors.orange
                ? Icons.warning
                : Icons.error,
        color: Colors.white,
      ),
    );
  }
}
