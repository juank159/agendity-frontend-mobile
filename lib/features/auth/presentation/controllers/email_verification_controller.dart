// // lib/features/auth/presentation/controllers/email_verification_controller.dart
// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:login_signup/features/auth/domain/usecases/request_verification_code_usecase.dart';
// import 'package:login_signup/features/auth/domain/usecases/verify_email_usecase.dart';

// class EmailVerificationController extends GetxController {
//   final RequestVerificationCodeUseCase requestCodeUseCase;
//   final VerifyEmailUseCase verifyEmailUseCase;

//   final email = ''.obs;
//   final codeController = TextEditingController();
//   final isLoading = false.obs;
//   final timeRemaining = 600.obs; // 10 minutos
//   final isTimerActive = false.obs;

//   Timer? _timer;

//   EmailVerificationController({
//     required this.requestCodeUseCase,
//     required this.verifyEmailUseCase,
//   });

//   @override
//   void onInit() {
//     super.onInit();
//     // Obtener email de argumentos de navegación
//     if (Get.arguments != null && Get.arguments['email'] != null) {
//       email.value = Get.arguments['email'];
//       requestVerificationCode(); // Solicitar código automáticamente
//     }
//   }

//   @override
//   void onClose() {
//     _timer?.cancel();
//     codeController.dispose();
//     super.onClose();
//   }

//   Future<void> requestVerificationCode() async {
//     if (email.value.isEmpty) {
//       _showSnackbar(
//         title: 'Error',
//         message: 'No se ha proporcionado un correo electrónico',
//         color: Colors.red,
//       );
//       return;
//     }

//     isLoading.value = true;

//     try {
//       final result = await requestCodeUseCase(email: email.value);

//       result.fold(
//         (failure) {
//           _showSnackbar(
//             title: 'Error',
//             message: failure.message,
//             color: Colors.red,
//           );
//         },
//         (success) {
//           _showSnackbar(
//             title: 'Código enviado',
//             message: 'Se ha enviado un código de verificación a tu correo',
//             color: Colors.green,
//           );
//           _startTimer();
//         },
//       );
//     } catch (e) {
//       _showSnackbar(
//         title: 'Error',
//         message: e.toString(),
//         color: Colors.red,
//       );
//     } finally {
//       isLoading.value = false;
//     }
//   }

//   Future<void> verifyEmail() async {
//     if (codeController.text.isEmpty) {
//       _showSnackbar(
//         title: 'Error',
//         message: 'Por favor, ingresa el código de verificación',
//         color: Colors.yellow[800]!,
//       );
//       return;
//     }

//     print(
//         'Enviando verificación - Email: ${email.value}, Código: ${codeController.text}');
//     isLoading.value = true;

//     try {
//       final result = await verifyEmailUseCase(
//         email: email.value,
//         code: codeController.text,
//       );

//       result.fold(
//         (failure) {
//           // Este bloque debería ejecutarse solo en caso de errores reales
//           print('Error en verificación: ${failure.message}');
//           _showSnackbar(
//             title: 'Error',
//             message: failure.message,
//             color: Colors.red,
//           );
//         },
//         (isVerified) {
//           if (isVerified) {
//             _timer?.cancel();
//             _showSnackbar(
//               title: 'Éxito',
//               message: 'Correo verificado correctamente',
//               color: Colors.green,
//             );

//             // Navegar después de un pequeño retraso para que el usuario vea el mensaje
//             Future.delayed(Duration(seconds: 2), () {
//               Get.offAllNamed('/login');
//             });
//           } else {
//             _showSnackbar(
//               title: 'Error',
//               message: 'La verificación no pudo completarse',
//               color: Colors.red,
//             );
//           }
//         },
//       );
//     } catch (e) {
//       print('Excepción no controlada en verificación: $e');
//       _showSnackbar(
//         title: 'Error',
//         message: 'Error inesperado durante la verificación',
//         color: Colors.red,
//       );
//     } finally {
//       isLoading.value = false;
//     }
//   }

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
//           title: 'Aviso',
//           message: 'El código ha expirado, solicita uno nuevo',
//           color: Colors.orange,
//         );
//       }
//     });
//   }

//   String get formattedTime {
//     final minutes = (timeRemaining.value / 60).floor();
//     final seconds = timeRemaining.value % 60;
//     return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
//   }

//   void _showSnackbar({
//     required String title,
//     required String message,
//     required Color color,
//   }) {
//     Get.snackbar(
//       title,
//       message,
//       snackPosition: SnackPosition.TOP,
//       backgroundColor: color.withOpacity(0.9),
//       colorText: Colors.white,
//       margin: const EdgeInsets.all(15),
//       borderRadius: 8,
//       duration: const Duration(seconds: 6),
//       icon: Icon(
//         color == Colors.green ? Icons.check_circle : Icons.error,
//         color: Colors.white,
//       ),
//     );
//   }
// }

// lib/features/auth/presentation/controllers/email_verification_controller.dart
// lib/features/auth/presentation/controllers/email_verification_controller.dart

// lib/features/auth/presentation/controllers/email_verification_controller.dart

// lib/features/auth/presentation/controllers/email_verification_controller.dart

import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/features/auth/domain/usecases/request_verification_code_usecase.dart';
import 'package:login_signup/features/auth/domain/usecases/verify_email_usecase.dart';

class EmailVerificationController extends GetxController {
  final RequestVerificationCodeUseCase requestCodeUseCase;
  final VerifyEmailUseCase verifyEmailUseCase;

  final email = ''.obs;
  late final TextEditingController codeController;
  final isLoading = false.obs;
  final timeRemaining = 600.obs; // 10 minutos
  final isTimerActive = false.obs;

  Timer? _timer;
  bool _isDisposed = false;

  EmailVerificationController({
    required this.requestCodeUseCase,
    required this.verifyEmailUseCase,
  });

  @override
  void onInit() {
    super.onInit();
    _isDisposed = false;
    codeController = TextEditingController();
  }

  // Este método es crucial
  @override
  void onClose() {
    _timer?.cancel();
    _isDisposed = true;
    codeController.dispose();
    super.onClose();
  }

  Future<void> requestVerificationCode() async {
    if (email.value.isEmpty) {
      _showSnackbar(
        title: 'Error',
        message: 'No se ha proporcionado un correo electrónico',
        color: Colors.red,
      );
      return;
    }

    isLoading.value = true;

    try {
      final result = await requestCodeUseCase(email: email.value);

      // Verificar si el controlador sigue vivo
      if (_isDisposed) return;

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
            title: 'Código enviado',
            message: 'Se ha enviado un código de verificación al correo',
            color: Colors.green,
          );
          _startTimer();
        },
      );
    } catch (e) {
      // Verificar si el controlador sigue vivo
      if (_isDisposed) return;

      _showSnackbar(
        title: 'Error',
        message: e.toString(),
        color: Colors.red,
      );
    } finally {
      // Verificar si el controlador sigue vivo
      if (!_isDisposed) {
        isLoading.value = false;
      }
    }
  }

  Future<Either<Failure, bool>> verifyEmail() async {
    if (_isDisposed) {
      return Left(ServerFailure(message: 'Controller has been disposed'));
    }

    if (codeController.text.isEmpty) {
      _showSnackbar(
        title: 'Error',
        message: 'Por favor, ingresa el código de verificación',
        color: Colors.yellow[800]!,
      );
      return Left(ServerFailure(message: 'Código no ingresado'));
    }

    print(
        'Enviando verificación - Email: ${email.value}, Código: ${codeController.text}');
    isLoading.value = true;

    try {
      final result = await verifyEmailUseCase(
        email: email.value,
        code: codeController.text,
      );

      // Verificar si el controlador sigue vivo
      if (_isDisposed) {
        return Left(ServerFailure(message: 'Controller has been disposed'));
      }

      result.fold(
        (failure) {
          print('Error en verificación: ${failure.message}');
          _showSnackbar(
            title: 'Error',
            message: failure.message,
            color: Colors.red,
          );
        },
        (isVerified) {
          if (isVerified) {
            _timer?.cancel();
            _showSnackbar(
              title: 'Éxito',
              message: 'Correo verificado correctamente',
              color: Colors.green,
            );
          } else {
            _showSnackbar(
              title: 'Error',
              message: 'La verificación no pudo completarse',
              color: Colors.red,
            );
          }
        },
      );

      // Verificar si el controlador sigue vivo
      if (_isDisposed) {
        return Left(ServerFailure(message: 'Controller has been disposed'));
      }

      isLoading.value = false;
      return result;
    } catch (e) {
      print('Excepción no controlada en verificación: $e');

      // Verificar si el controlador sigue vivo
      if (_isDisposed) {
        return Left(ServerFailure(message: 'Controller has been disposed'));
      }

      _showSnackbar(
        title: 'Error',
        message: 'Error inesperado durante la verificación',
        color: Colors.red,
      );
      isLoading.value = false;
      return Left(ServerFailure(message: e.toString()));
    }
  }

  void _startTimer() {
    _timer?.cancel();
    timeRemaining.value = 600; // 10 minutos
    isTimerActive.value = true;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      // Verificar si el controlador sigue vivo
      if (_isDisposed) {
        timer.cancel();
        return;
      }

      if (timeRemaining.value > 0) {
        timeRemaining.value--;
      } else {
        timer.cancel();
        isTimerActive.value = false;
        _showSnackbar(
          title: 'Aviso',
          message: 'El código ha expirado, solicita uno nuevo',
          color: Colors.orange,
        );
      }
    });
  }

  String get formattedTime {
    final minutes = (timeRemaining.value / 60).floor();
    final seconds = timeRemaining.value % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _showSnackbar({
    required String title,
    required String message,
    required Color color,
  }) {
    // Verificar si el controlador sigue vivo
    if (_isDisposed) return;

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
