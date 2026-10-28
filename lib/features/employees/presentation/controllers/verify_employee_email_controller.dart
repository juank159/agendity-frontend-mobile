import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/routes/routes.dart';
import 'package:login_signup/features/employees/domain/usecases/request_employee_verification_code_usecase.dart';
import 'package:login_signup/features/employees/domain/usecases/verify_employee_email_usecase.dart';
import 'package:login_signup/features/employees/presentation/bindings/employees_binding.dart';
import 'package:login_signup/features/employees/presentation/screens/employees_list_screen.dart';

class VerifyEmployeeEmailController extends GetxController {
  // Casos de uso
  final RequestEmployeeVerificationCodeUseCase requestVerificationCodeUseCase;
  final VerifyEmployeeEmailUseCase verifyEmployeeEmailUseCase;

  // Propiedades reactivas
  final RxString email = ''.obs;
  final RxString _employeeName = ''.obs;
  final RxString _employeeId = ''.obs;
  final Rx<String?> errorMessage = Rx<String?>(null);
  final RxBool isLoading = false.obs;
  final RxBool isTimerActive = false.obs;
  final RxBool canResendCode = true.obs;
  final RxInt resendCountdown = 0.obs;
  final RxBool _isDisposed =
      false.obs; // Indicador para saber si está desechado

  TextEditingController? codeController;

  // Variables para los timers
  Timer? _resendTimer;
  Timer? _codeExpirationTimer;

  // Getters
  String get employeeName => _employeeName.value;
  String get employeeId => _employeeId.value;
  String get formattedTime => _formatTime(resendCountdown.value);
  String get formattedResendTime => _formatTime(resendCountdown.value);

  // Setters
  set employeeName(String value) => _employeeName.value = value;
  set employeeId(String value) => _employeeId.value = value;

  VerifyEmployeeEmailController({
    required this.requestVerificationCodeUseCase,
    required this.verifyEmployeeEmailUseCase,
  });

  @override
  void onInit() {
    super.onInit();
    _isDisposed.value = false;
    codeController = TextEditingController();

    // Inicializar parámetros desde los argumentos si están disponibles
    if (Get.arguments != null) {
      try {
        final args = Get.arguments as Map<String, dynamic>;
        email.value = args['email'] ?? '';
        _employeeName.value = args['employee_name'] ?? '';
        _employeeId.value = args['employee_id'] ?? '';

        print(
            'Controlador inicializado con email: ${email.value}, nombre: ${_employeeName.value}, id: ${_employeeId.value}');

        // Solicitar código automáticamente si hay un email
        if (email.value.isNotEmpty) {
          requestVerificationCode();
        }
      } catch (e) {
        print('Error al procesar argumentos: $e');
      }
    }
  }

  @override
  void onClose() {
    print('Cerrando VerifyEmployeeEmailController');
    _isDisposed.value = true; // Primero marca como dispuesto
    _cleanupResources(); // Luego limpia recursos
    super.onClose();
  }

  // Método para limpiar recursos de forma segura
  void _cleanupResources() {
    try {
      // Cancelar timers
      if (_resendTimer != null) {
        _resendTimer?.cancel();
        _resendTimer = null;
      }

      if (_codeExpirationTimer != null) {
        _codeExpirationTimer?.cancel();
        _codeExpirationTimer = null;
      }

      // IMPORTANTE: Agrega una verificación adicional para evitar problemas
      if (codeController != null && !_isDisposed.value) {
        try {
          codeController!.dispose();
          codeController = null;
        } catch (e) {
          print('Error controlado al disponer codeController: $e');
        }
      }
    } catch (e) {
      print('Error controlado al limpiar recursos: $e');
    }
  }

  // Método público para que otros componentes puedan liberar recursos
  void disposeResources() {
    if (!_isDisposed.value) {
      print('Realizando limpieza de recursos explícita');
      _isDisposed.value = true; // Marca como dispuesto primero
      _cleanupResources();
    } else {
      print('Recursos ya limpiados previamente');
    }
  }

  // Método para solicitar un código de verificación
  Future<void> requestVerificationCode() async {
    if (_isDisposed.value) return;

    if (email.value.isEmpty || employeeId.isEmpty) {
      errorMessage.value = 'El email y el ID del empleado son requeridos';
      return;
    }

    try {
      isLoading.value = true;
      errorMessage.value = null;

      final result = await requestVerificationCodeUseCase(email.value);
      if (_isDisposed.value) return;

      result.fold((failure) {
        // Nunca se envía un código inventado: se muestra el error y el
        // usuario puede reintentar con el botón de reenvío.
        errorMessage.value =
            'No se pudo enviar el código de verificación. Intenta reenviarlo.';
        canResendCode.value = true;

        Get.snackbar(
          'Error',
          '${failure.message}\nPulsa "Reenviar código" para intentarlo de nuevo.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red[100],
          colorText: Colors.red[900],
          duration: const Duration(seconds: 5),
        );
      }, (_) {
        _startTimer();
        canResendCode.value = false;
        _startResendCountdown();

        Get.snackbar(
          'Código enviado',
          'Se ha enviado un código de verificación a ${email.value}',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green[100],
          colorText: Colors.green[900],
        );
      });
    } finally {
      if (!_isDisposed.value) isLoading.value = false;
    }
  }

  /// Verifica el código. El backend activa al empleado en el mismo paso.
  Future<void> verifyEmail() async {
    if (_isDisposed.value || codeController == null) return;

    final code = codeController!.text.trim();
    if (code.isEmpty) {
      errorMessage.value = 'Por favor ingresa el código de verificación';
      return;
    }

    try {
      isLoading.value = true;
      errorMessage.value = null;

      final result = await verifyEmployeeEmailUseCase(
          VerifyEmployeeEmailParams(employeeId: employeeId, code: code));
      if (_isDisposed.value) return;

      final verified = result.fold((failure) {
        errorMessage.value = failure.message;
        return false;
      }, (_) => true);
      if (!verified) return;

      _resendTimer?.cancel();
      _resendTimer = null;
      _codeExpirationTimer?.cancel();
      _codeExpirationTimer = null;

      Get.snackbar(
        'Éxito',
        'Email verificado correctamente',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green[100],
        colorText: Colors.green[900],
        duration: const Duration(seconds: 2),
      );

      // Marcar como dispuesto antes de navegar para evitar operaciones posteriores
      _isDisposed.value = true;

      // Pequeño delay para asegurar que el snackbar sea visible
      await Future.delayed(const Duration(milliseconds: 500));
      safeNavigateToEmployeesList();
    } finally {
      if (!_isDisposed.value) isLoading.value = false;
    }
  }

  // Método para navegación segura
  void safeNavigateToEmployeesList() {
    try {
      print('Navegando a pantalla de lista de empleados');

      // IMPORTANTE: Primero configura una bandera para evitar más operaciones
      _isDisposed.value = true;

      // Agregar un pequeño retraso para asegurar que otras operaciones terminen
      Future.delayed(const Duration(milliseconds: 300), () {
        try {
          // Intenta usar offAllNamed que es más seguro para este tipo de navegación
          print('Intentando navegar con offAllNamed a ${GetRoutes.employees}');
          Get.offAllNamed(GetRoutes.employees);
        } catch (e) {
          print('Error en navegación primaria: $e');

          // Plan B: Intenta con otra técnica de navegación
          try {
            print('Intentando navegación alternativa con offAll');
            Get.offAll(() => const EmployeesListScreen(),
                binding: EmployeesBinding());
          } catch (e2) {
            print('Error en navegación secundaria: $e2');

            // Plan C: Intenta una navegación más básica
            try {
              print('Último intento de navegación con off');
              Get.off(() => const EmployeesListScreen());
            } catch (e3) {
              print('Falló toda navegación: $e3');
            }
          }
        }
      });
    } catch (e) {
      print('Error general al preparar navegación: $e');
    }
  }

  // Método para iniciar el temporizador del código
  void _startTimer() {
    if (_isDisposed.value) return;

    print('Iniciando timer de expiración de código');
    isTimerActive.value = true;

    // Cancelar timer anterior si existe
    if (_codeExpirationTimer != null) {
      _codeExpirationTimer?.cancel();
      _codeExpirationTimer = null;
    }

    // Configurar el tiempo de expiración (10 minutos)
    int expirationTime = 10 * 60; // 10 minutos en segundos
    resendCountdown.value = expirationTime;

    _codeExpirationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isDisposed.value) {
        timer.cancel();
        return;
      }

      if (resendCountdown.value <= 0) {
        print('Código expirado');
        timer.cancel();
        isTimerActive.value = false;
        errorMessage.value =
            'El código ha expirado. Por favor, solicita uno nuevo.';
      } else {
        resendCountdown.value--;
      }
    });

    print('Timer de expiración iniciado');
  }

  // Método para el temporizador de reenvío
  void _startResendCountdown() {
    if (_isDisposed.value) return;

    print('Iniciando timer para reenvío de código');

    // Cancelar timer anterior si existe
    if (_resendTimer != null) {
      _resendTimer?.cancel();
      _resendTimer = null;
    }

    // 60 segundos para reenviar
    resendCountdown.value = 60;
    canResendCode.value = false;

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isDisposed.value) {
        timer.cancel();
        return;
      }

      if (resendCountdown.value <= 0) {
        print('Timer de reenvío completado, habilitando reenvío');
        timer.cancel();
        canResendCode.value = true;
      } else {
        resendCountdown.value--;
      }
    });

    print('Timer de reenvío iniciado');
  }

  // Método para formatear tiempo
  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}
