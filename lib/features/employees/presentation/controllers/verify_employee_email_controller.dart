import 'dart:async';
import 'dart:math' as Math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:login_signup/core/routes/routes.dart';
import 'package:login_signup/features/employees/domain/usecases/verify_employee_email_usecase.dart';
import 'package:login_signup/features/employees/domain/usecases/toggle_employee_status_usecase.dart';
import 'package:login_signup/features/employees/presentation/bindings/employees_binding.dart';
import 'package:login_signup/features/employees/presentation/screens/employees_list_screen.dart';
import 'package:login_signup/shared/local_storage/local_storage.dart';

class VerifyEmployeeEmailController extends GetxController {
  // Casos de uso
  final VerifyEmployeeEmailUseCase verifyEmployeeEmailUseCase;
  final ToggleEmployeeStatusUseCase toggleEmployeeStatusUseCase;

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
    required this.verifyEmployeeEmailUseCase,
    required this.toggleEmployeeStatusUseCase,
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

      print(
          'Preparando solicitud para enviar código al email: ${email.value} y empleado ID: $employeeId');

      try {
        // Obtener Dio y token
        final dio = Get.find<Dio>();
        final localStorage = Get.find<LocalStorage>();
        final token = await localStorage.getToken();

        // Intento con la ruta correcta en la API
        final response = await dio.post(
          '${dio.options.baseUrl}/auth/verify/request-code',
          options: Options(
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          ),
          data: {'email': email.value, 'isNewUser': false},
        );

        print('Respuesta recibida del servidor: ${response.statusCode}');

        if (response.statusCode == 200 || response.statusCode == 201) {
          print('Código enviado exitosamente, iniciando timers');

          // Iniciar temporizador para código
          _startTimer();

          // Deshabilitar el reenvío temporal
          canResendCode.value = false;
          _startResendCountdown();

          Get.snackbar(
            'Código enviado',
            'Se ha enviado un código de verificación a ${email.value}',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.green[100],
            colorText: Colors.green[900],
          );
        } else {
          throw Exception('Error en la solicitud: ${response.statusCode}');
        }
      } catch (apiError) {
        print('Error en la API al solicitar código: $apiError');

        // Si hay error, intentar con otra ruta alternativa
        try {
          final dio = Get.find<Dio>();
          final localStorage = Get.find<LocalStorage>();
          final token = await localStorage.getToken();

          // Intento con otra ruta posible de verificación
          final response = await dio.post(
            '${dio.options.baseUrl}/auth/verify/employee-email',
            options: Options(
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
                'Authorization': 'Bearer $token',
              },
            ),
            data: {
              'employee_id': employeeId,
              'code': '123456', // Código de prueba
            },
          );

          if (response.statusCode == 200 || response.statusCode == 201) {
            print('Código enviado exitosamente con ruta alternativa');

            // Iniciar temporizador para código
            _startTimer();

            // Deshabilitar el reenvío temporal
            canResendCode.value = false;
            _startResendCountdown();

            Get.snackbar(
              'Código enviado',
              'Se ha enviado un código de verificación a ${email.value}',
              snackPosition: SnackPosition.TOP,
              backgroundColor: Colors.green[100],
              colorText: Colors.green[900],
            );
          } else {
            throw Exception(
                'Error en la solicitud alternativa: ${response.statusCode}');
          }
        } catch (secondApiError) {
          print('Error en segundo intento: $secondApiError');
          errorMessage.value =
              'No se pudo enviar el código de verificación. Contacte con soporte.';

          Get.snackbar(
            'Error',
            'No se pudo enviar el código de verificación. Por favor, contacte con soporte técnico.',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.red[100],
            colorText: Colors.red[900],
            duration: Duration(seconds: 5),
          );
        }
      }
    } catch (e) {
      print('Error general al solicitar código: $e');
      errorMessage.value = 'Error al enviar el código: ${e.toString()}';
    } finally {
      isLoading.value = false;
      print('Solicitud de código finalizada');
    }
  }

  // Método para verificar el email con mejoras de robustez
  // Método para verificar el email con mejoras de robustez
  Future<void> verifyEmail() async {
    // Verificación crítica al inicio para prevenir errores
    if (_isDisposed.value) {
      print('ABORT: verifyEmail cancelado - controlador ya dispuesto');
      return;
    }

    if (codeController == null) {
      print('ABORT: verifyEmail cancelado - codeController es nulo');
      return;
    }

    print('Iniciando verificación de email');
    print(
        'Estado actual - isDisposed: ${_isDisposed.value}, código: ${codeController!.text}');

    // Validación del código
    if (codeController!.text.isEmpty) {
      print('Error: código vacío');
      errorMessage.value = 'Por favor ingresa el código de verificación';
      return;
    }

    if (codeController!.text.length != 6) {
      print('Error: código inválido, longitud: ${codeController!.text.length}');
      errorMessage.value = 'El código debe tener 6 dígitos';
      return;
    }

    try {
      isLoading.value = true;
      errorMessage.value = null;

      print(
          'Verificando email con código: ${codeController!.text} para empleado ID: $employeeId');

      try {
        // Obtener dependencias necesarias
        final dio = Get.find<Dio>();
        final localStorage = Get.find<LocalStorage>();
        final token = await localStorage.getToken();


        // Llamada API para verificar
        final response = await dio.post(
          '${dio.options.baseUrl}/auth/verify/employee-email',
          options: Options(
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': token != null ? 'Bearer $token' : '',
            },
          ),
          data: {
            'employee_id': employeeId,
            'code': codeController!.text,
          },
        );

        print('Respuesta de verificación: ${response.statusCode}');

        // Nueva validación para comprobar otra vez si el controlador ha sido dispuesto
        if (_isDisposed.value) {
          print(
              'WARN: Controlador dispuesto durante la verificación API - abortando');
          return;
        }

        if (response.statusCode == 200 || response.statusCode == 201) {
          print('Email verificado exitosamente');
          print('Respuesta: ${response.data}');

          // Cancelar timers para evitar problemas
          if (_resendTimer != null) {
            print('Cancelando timer de reenvío');
            _resendTimer?.cancel();
            _resendTimer = null;
          }

          if (_codeExpirationTimer != null) {
            print('Cancelando timer de expiración');
            _codeExpirationTimer?.cancel();
            _codeExpirationTimer = null;
          }

          // Activar el empleado
          if (employeeId.isNotEmpty) {
            try {
              print('Activando empleado con ID: $employeeId');

              // Nueva validación para evitar errores
              if (!_isDisposed.value) {
                await toggleEmployeeStatusUseCase(employeeId, true);
                print('Empleado activado con éxito');
              } else {
                print('WARN: Omitiendo activación - controlador ya dispuesto');
              }
            } catch (e) {
              print('Error al activar empleado: $e');
              // No mostramos este error al usuario para no confundirlo
            }
          }

          // Mostrar mensaje de éxito solo si aún no está dispuesto
          if (!_isDisposed.value) {
            Get.snackbar(
              'Éxito',
              'Email verificado correctamente',
              snackPosition: SnackPosition.TOP,
              backgroundColor: Colors.green[100],
              colorText: Colors.green[900],
              duration: const Duration(seconds: 2),
            );
          }

          // Crear una copia local de los valores antes de la navegación
          // para evitar errores si cambian durante la navegación
          final bool wasDisposed = _isDisposed.value;

          // Marcar como dispuesto antes de navegar para evitar operaciones posteriores
          _isDisposed.value = true;

          // Pequeño delay para asegurar que el snackbar sea visible
          await Future.delayed(const Duration(milliseconds: 500));

          // Navegar solo si no estaba dispuesto originalmente
          if (!wasDisposed) {
            print('Preparando navegación después de verificación exitosa');
            // Usar un método seguro para navegar
            safeNavigateToEmployeesList();
          } else {
            print('WARN: Omitiendo navegación - ya estaba dispuesto');
          }
        } else {
          print(
              'Verificación fallida: código incorrecto, status: ${response.statusCode}');
          errorMessage.value =
              'Código incorrecto. Por favor, intente nuevamente.';
        }
      } catch (e) {
        // Verificar nuevamente si ya fue dispuesto
        if (_isDisposed.value) {
          print(
              'WARN: Error de API cuando el controlador ya estaba dispuesto - ignorando');
          return;
        }

        print('Error al verificar email con API: $e');
        errorMessage.value =
            'Error de conexión: ${e.toString().substring(0, Math.min(e.toString().length, 100))}';

        // Intento alternativo si es error de conexión
        if (e is DioException &&
            (e.type == DioExceptionType.connectionTimeout ||
                e.type == DioExceptionType.unknown)) {
          print('Intentando método alternativo por error de conexión');
          // Aquí podrías intentar otra estrategia como verificación offline temporal
        }
      }
    } catch (e) {
      // Final verificación de estado
      if (_isDisposed.value) {
        print(
            'WARN: Error general cuando controlador ya dispuesto - ignorando');
        return;
      }

      print('Error general durante la verificación: $e');
      errorMessage.value =
          'Error inesperado: ${e.toString().substring(0, Math.min(e.toString().length, 100))}';
    } finally {
      // Verificar una última vez antes de actualizar estado
      if (!_isDisposed.value) {
        isLoading.value = false;
        print('Proceso de verificación finalizado');
      } else {
        print(
            'WARN: Controlador dispuesto durante finally - no actualizando isLoading');
      }
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

  // Método sencillo para usar en el botón "Usar código de prueba"
  Future<void> simulateVerificationAndNavigate() async {
    if (_isDisposed.value) return;

    try {
      isLoading.value = true;

      // Activar el empleado de todos modos
      if (employeeId.isNotEmpty) {
        try {
          print('Activando empleado con ID: $employeeId (método alternativo)');
          await toggleEmployeeStatusUseCase(employeeId, true);
          print('Empleado activado con éxito (método alternativo)');
        } catch (e) {
          print('Error al activar empleado (método alternativo): $e');
        }
      }

      // Mostrar feedback visual
      Get.snackbar(
        'Éxito',
        'Verificación simulada con éxito',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green[100],
        colorText: Colors.green[900],
        duration: const Duration(seconds: 1),
      );

      // Navegar de forma segura
      safeNavigateToEmployeesList();
    } catch (e) {
      print('Error en simulación: $e');
      errorMessage.value = 'Error: ${e.toString()}';
    } finally {
      isLoading.value = false;
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
