// lib/features/auth/presentation/controllers/email_verification_controller.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/features/auth/domain/usecases/request_verification_code_usecase.dart';
import 'package:login_signup/features/auth/domain/usecases/verify_email_usecase.dart';
import 'package:login_signup/shared/local_storage/local_storage.dart';

class EmailVerificationController extends GetxController {
  final RequestVerificationCodeUseCase requestCodeUseCase;
  final VerifyEmailUseCase verifyEmailUseCase;

  final email = ''.obs;
  final codeController = TextEditingController();
  final isLoading = false.obs;
  final timeRemaining = 600.obs; // 10 minutos
  final isTimerActive = false.obs;

  // ← NUEVO: Variable para saber si es un usuario nuevo
  final isNewUser = true.obs;

  Timer? _timer;

  EmailVerificationController({
    required this.requestCodeUseCase,
    required this.verifyEmailUseCase,
  }) {
    // ← DEBUGGING: Constructor
    print('🔧 EmailVerificationController constructor llamado');
  }

  @override
  void onInit() {
    super.onInit();
    print('🔥 EmailVerificationController inicializado');

    // Obtener email y tipo de usuario de argumentos de navegación
    if (Get.arguments != null) {
      print('📧 Argumentos recibidos: ${Get.arguments}');

      if (Get.arguments['email'] != null) {
        email.value = Get.arguments['email'];
        print('📧 Email obtenido: ${email.value}');
      } else {
        print('⚠️ No se encontró email en argumentos');
      }

      // ← NUEVO: Verificar si es nuevo usuario (por defecto true para registro)
      if (Get.arguments['isNewUser'] != null) {
        isNewUser.value = Get.arguments['isNewUser'];
      }

      print('👤 Es nuevo usuario: ${isNewUser.value}');

      // ← CAMBIO: Solo solicitar código si el email no está vacío
      if (email.value.isNotEmpty) {
        print('📧 Email válido, solicitando código automáticamente...');
        requestVerificationCode();
      } else {
        print('❌ Email vacío, no se puede solicitar código');
        _showSnackbar(
          title: 'Error',
          message:
              'No se recibió el email correctamente. Por favor, regresa e intenta de nuevo.',
          color: Colors.red,
        );
      }
    } else {
      print('❌ No se recibieron argumentos de navegación');
    }
  }

  @override
  void onClose() {
    try {
      _timer?.cancel();

      // ← PROTECCIÓN: Verificar si el controlador ya fue disposed
      if (!codeController.text.isEmpty || codeController.text.isEmpty) {
        // Si podemos acceder al texto sin error, entonces no está disposed
        codeController.dispose();
      }
    } catch (e) {
      // Si hay error, significa que ya estaba disposed, ignorar
      print('⚠️ TextEditingController ya estaba disposed: $e');
    }

    super.onClose();
  }

  Future<void> requestVerificationCode() async {
    if (email.value.isEmpty) {
      print('❌ Email vacío, no se puede solicitar código');
      _showSnackbar(
        title: 'Error',
        message: 'No se ha proporcionado un correo electrónico',
        color: Colors.red,
      );
      return;
    }

    print('📧 Solicitando código de verificación para: ${email.value}');
    print('👤 Es nuevo usuario: ${isNewUser.value}');

    isLoading.value = true;

    try {
      // ← CORREGIDO: Pasar el parámetro isNewUser
      final result = await requestCodeUseCase(
        email: email.value,
        isNewUser: isNewUser.value, // ← ESTO ERA LO QUE FALTABA
      );

      result.fold(
        (failure) {
          print('❌ Error solicitando código: ${failure.message}');
          _showSnackbar(
            title: 'Error',
            message: failure.message,
            color: Colors.red,
          );
        },
        (success) {
          print('✅ Código solicitado exitosamente');
          _showSnackbar(
            title: 'Código enviado',
            message: 'Se ha enviado un código de verificación a tu correo',
            color: Colors.green,
          );
          _startTimer();
        },
      );
    } catch (e) {
      print('❌ Excepción solicitando código: ${e.toString()}');
      _showSnackbar(
        title: 'Error',
        message: e.toString(),
        color: Colors.red,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> verifyEmail() async {
    if (codeController.text.isEmpty) {
      _showSnackbar(
        title: 'Error',
        message: 'Por favor, ingresa el código de verificación',
        color: Colors.yellow[800]!,
      );
      return;
    }

    print(
        '🔍 Verificando email - Email: ${email.value}, Código: ${codeController.text}');
    isLoading.value = true;

    try {
      final result = await verifyEmailUseCase(
        email: email.value,
        code: codeController.text,
      );

      result.fold(
        (failure) {
          print('❌ Error en verificación: ${failure.message}');
          _showSnackbar(
            title: 'Error',
            message: failure.message,
            color: Colors.red,
          );
        },
        (isVerified) async {
          // ← AGREGAR: async aquí
          if (isVerified) {
            print('✅ Email verificado correctamente');
            _timer?.cancel();
            _showSnackbar(
              title: 'Éxito',
              message:
                  'Correo verificado correctamente. Ahora puedes iniciar sesión.',
              color: Colors.green,
            );

            // ← CORREGIDO: Limpiar token para forzar login manual
            try {
              // Acceder al localStorage para limpiar el token
              final localStorage = Get.find<LocalStorage>();
              await localStorage.deleteToken();
              print(
                  '🔑 Token eliminado - usuario debe iniciar sesión manualmente');
            } catch (e) {
              print('⚠️ Error eliminando token: $e');
            }

            // Navegar al login para que inicie sesión manualmente
            Future.delayed(const Duration(seconds: 2), () {
              Get.offAllNamed('/login', arguments: {
                'message':
                    'Email verificado correctamente. Inicia sesión con tus credenciales.',
                'messageType': 'success'
              });
            });
          } else {
            print('❌ Verificación falló');
            _showSnackbar(
              title: 'Error',
              message: 'La verificación no pudo completarse',
              color: Colors.red,
            );
          }
        },
      );
    } catch (e) {
      print('❌ Excepción en verificación: $e');
      _showSnackbar(
        title: 'Error',
        message: 'Error inesperado durante la verificación',
        color: Colors.red,
      );
    } finally {
      isLoading.value = false;
    }
  }

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
