import 'package:login_signup/core/routes/routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/usecases/request_verification_code_usecase.dart';

class RegisterController extends GetxController {
  final RegisterUseCase registerUseCase;
  final RequestVerificationCodeUseCase requestVerificationCodeUseCase;

  // Controllers de texto
  final nameController = TextEditingController();
  final lastnameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  // Estado de carga y visibilidad
  final isLoading = false.obs;
  final isPasswordVisible = false.obs;

  // Estados de validación por campo
  final nameError = ''.obs;
  final lastnameError = ''.obs;
  final phoneError = ''.obs;
  final emailError = ''.obs;
  final passwordError = ''.obs;

  // Validaciones de contraseña
  final passwordValidations = <String, bool>{}.obs;

  RegisterController({
    required this.registerUseCase,
    required this.requestVerificationCodeUseCase,
  });

  @override
  void onClose() {
    nameController.dispose();
    lastnameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  // Alternar visibilidad de contraseña
  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  // Validar contraseña y actualizar indicadores
  void validatePassword() {
    final password = passwordController.text;

    passwordValidations.value = {
      'length': password.length >= 8,
      'uppercase': RegExp(r'[A-Z]').hasMatch(password),
      'lowercase': RegExp(r'[a-z]').hasMatch(password),
      'number': RegExp(r'\d').hasMatch(password),
      'special': RegExp(r'[@$!%*?&]').hasMatch(password),
    };

    // Limpiar error si la contraseña es válida
    if (password.isEmpty) {
      passwordError.value = '';
    } else if (!_isPasswordValid()) {
      passwordError.value = 'La contraseña no cumple con todos los requisitos';
    } else {
      passwordError.value = '';
    }
  }

  bool _isPasswordValid() {
    return passwordValidations.values.every((isValid) => isValid);
  }

  // Validación completa antes del registro
  bool validateAllFields() {
    bool isValid = true;

    // Limpiar errores previos
    nameError.value = '';
    lastnameError.value = '';
    phoneError.value = '';
    emailError.value = '';
    passwordError.value = '';

    final name = nameController.text.trim();
    final lastname = lastnameController.text.trim();
    final phone = phoneController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;

    // Validar nombre
    if (name.isEmpty) {
      nameError.value = 'El nombre es obligatorio';
      isValid = false;
    } else if (name.length < 2) {
      nameError.value = 'El nombre debe tener al menos 2 caracteres';
      isValid = false;
    } else if (name.length > 50) {
      nameError.value = 'El nombre no puede exceder 50 caracteres';
      isValid = false;
    } else if (!RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$').hasMatch(name)) {
      nameError.value = 'El nombre solo puede contener letras y espacios';
      isValid = false;
    }

    // Validar apellido
    if (lastname.isEmpty) {
      lastnameError.value = 'El apellido es obligatorio';
      isValid = false;
    } else if (lastname.length < 2) {
      lastnameError.value = 'El apellido debe tener al menos 2 caracteres';
      isValid = false;
    } else if (lastname.length > 50) {
      lastnameError.value = 'El apellido no puede exceder 50 caracteres';
      isValid = false;
    } else if (!RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$').hasMatch(lastname)) {
      lastnameError.value = 'El apellido solo puede contener letras y espacios';
      isValid = false;
    }

    // Validar teléfono
    if (phone.isEmpty) {
      phoneError.value = 'El teléfono es obligatorio';
      isValid = false;
    } else if (!RegExp(r'^[0-9]{10}$').hasMatch(phone)) {
      phoneError.value = 'El teléfono debe contener exactamente 10 dígitos';
      isValid = false;
    }

    // Validar email
    if (email.isEmpty) {
      emailError.value = 'El correo electrónico es obligatorio';
      isValid = false;
    } else if (!email.isEmail) {
      emailError.value = 'Ingrese un correo electrónico válido';
      isValid = false;
    }

    // Validar contraseña
    if (password.isEmpty) {
      passwordError.value = 'La contraseña es obligatoria';
      isValid = false;
    } else {
      validatePassword();
      if (!_isPasswordValid()) {
        passwordError.value =
            'La contraseña debe cumplir con todos los requisitos de seguridad';
        isValid = false;
      }
    }

    return isValid;
  }

  Future<void> registerUser() async {
    print('🔥 Iniciando validación...');

    // Validar campos primero
    if (!validateAllFields()) {
      _showSnackbar(
        title: 'Error de validación',
        message: 'Por favor, corrija los errores antes de continuar',
        color: Colors.red,
      );
      return;
    }

    print('🔥 Validación exitosa, iniciando registro...');
    isLoading.value = true;

    try {
      final result = await registerUseCase(
        name: nameController.text.trim(),
        lastname: lastnameController.text.trim(),
        email: emailController.text.trim(),
        phone: phoneController.text.trim(),
        password: passwordController.text,
      );

      await result.fold(
        (failure) {
          print('❌ Error en registro: ${failure.message}');

          // Manejar errores específicos del backend
          String errorMessage = failure.message;
          if (errorMessage.contains('email')) {
            emailError.value = 'Este correo ya está registrado';
          } else if (errorMessage.contains('teléfono') ||
              errorMessage.contains('phone')) {
            phoneError.value = 'Este teléfono ya está registrado';
          }

          _showSnackbar(
            title: 'Error de registro',
            message: failure.message,
            color: Colors.red,
          );
        },
        (user) async {
          print('✅ Usuario registrado exitosamente');

          _showSnackbar(
            title: '¡Registro exitoso!',
            message:
                'Tu cuenta ha sido creada. Enviando código de verificación...',
            color: Colors.green,
          );

          // Solicitar código de verificación automáticamente
          final email = emailController.text.trim();
          print('📧 Solicitando código de verificación para: $email');

          final codeResult = await requestVerificationCodeUseCase(
            email: email,
            isNewUser: true,
          );

          await codeResult.fold(
            (codeFailure) {
              print('❌ Error solicitando código: ${codeFailure.message}');

              _showSnackbar(
                title: 'Advertencia',
                message:
                    'Cuenta creada exitosamente, pero hubo un problema enviando el código de verificación.',
                color: Colors.orange,
              );

              clearInputs();

              Future.delayed(const Duration(milliseconds: 1000), () {
                Get.offAllNamed(GetRoutes.verifyEmail, arguments: {
                  'email': email,
                  'isNewUser': true,
                });
              });
            },
            (success) {
              print('✅ Código de verificación enviado exitosamente');

              _showSnackbar(
                title: '¡Código enviado!',
                message:
                    'Revisa tu correo electrónico para verificar tu cuenta.',
                color: Colors.green,
              );

              clearInputs();

              Future.delayed(const Duration(milliseconds: 1000), () {
                Get.offAllNamed(GetRoutes.verifyEmail, arguments: {
                  'email': email,
                  'isNewUser': true,
                });
              });
            },
          );
        },
      );
    } catch (e) {
      print('❌ Error inesperado en registro: ${e.toString()}');
      _showSnackbar(
        title: 'Error inesperado',
        message: 'Ocurrió un error inesperado. Inténtalo nuevamente.',
        color: Colors.red,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void clearInputs() {
    nameController.clear();
    lastnameController.clear();
    phoneController.clear();
    emailController.clear();
    passwordController.clear();

    // Limpiar errores
    nameError.value = '';
    lastnameError.value = '';
    phoneError.value = '';
    emailError.value = '';
    passwordError.value = '';

    // Limpiar validaciones de contraseña
    passwordValidations.clear();
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
      duration: const Duration(seconds: 4),
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

  // Método helper para obtener el color del indicador de validación
  Color getValidationColor(bool isValid) {
    return isValid ? Colors.green : Colors.red;
  }

  // Método helper para obtener el icono del indicador de validación
  IconData getValidationIcon(bool isValid) {
    return isValid ? Icons.check_circle : Icons.cancel;
  }
}

// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:login_signup/features/auth/domain/usecases/register_usecase.dart';

// class RegisterController extends GetxController {
//   final RegisterUseCase registerUseCase;

//   // Controllers de texto
//   final nameController = TextEditingController();
//   final lastnameController = TextEditingController();
//   final phoneController = TextEditingController();
//   final emailController = TextEditingController();
//   final passwordController = TextEditingController();

//   // Estados reactivos
//   final isLoading = false.obs;
//   final isPasswordVisible = false.obs;

//   // Errores de validación
//   final nameError = ''.obs;
//   final lastnameError = ''.obs;
//   final phoneError = ''.obs;
//   final emailError = ''.obs;
//   final passwordError = ''.obs;

//   // Validaciones de contraseña
//   final passwordValidations = <String, bool>{}.obs;

//   RegisterController({required this.registerUseCase});

//   @override
//   void onClose() {
//     nameController.dispose();
//     lastnameController.dispose();
//     phoneController.dispose();
//     emailController.dispose();
//     passwordController.dispose();
//     super.onClose();
//   }

//   // Toggle para mostrar/ocultar contraseña
//   void togglePasswordVisibility() {
//     isPasswordVisible.value = !isPasswordVisible.value;
//   }

//   // Validar contraseña y mostrar indicadores visuales
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

//   // Iconos para validación
//   IconData getValidationIcon(bool isValid) {
//     return isValid ? Icons.check_circle : Icons.cancel;
//   }

//   // Colores para validación
//   Color getValidationColor(bool isValid) {
//     return isValid ? Colors.green : Colors.red;
//   }

//   // Validar campos individuales
//   bool _validateName() {
//     final name = nameController.text.trim();
//     if (name.isEmpty) {
//       nameError.value = 'El nombre es obligatorio';
//       return false;
//     }
//     if (name.length < 2) {
//       nameError.value = 'El nombre debe tener al menos 2 caracteres';
//       return false;
//     }
//     if (!RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$').hasMatch(name)) {
//       nameError.value = 'El nombre solo puede contener letras';
//       return false;
//     }
//     nameError.value = '';
//     return true;
//   }

//   bool _validateLastname() {
//     final lastname = lastnameController.text.trim();
//     if (lastname.isEmpty) {
//       lastnameError.value = 'Los apellidos son obligatorios';
//       return false;
//     }
//     if (lastname.length < 2) {
//       lastnameError.value = 'Los apellidos deben tener al menos 2 caracteres';
//       return false;
//     }
//     if (!RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$').hasMatch(lastname)) {
//       lastnameError.value = 'Los apellidos solo pueden contener letras';
//       return false;
//     }
//     lastnameError.value = '';
//     return true;
//   }

//   bool _validatePhone() {
//     final phone = phoneController.text.trim();
//     if (phone.isEmpty) {
//       phoneError.value = 'El teléfono es obligatorio';
//       return false;
//     }
//     if (!RegExp(r'^[0-9]{10}$').hasMatch(phone)) {
//       phoneError.value = 'El teléfono debe contener exactamente 10 dígitos';
//       return false;
//     }
//     phoneError.value = '';
//     return true;
//   }

//   bool _validateEmail() {
//     final email = emailController.text.trim();
//     if (email.isEmpty) {
//       emailError.value = 'El correo electrónico es obligatorio';
//       return false;
//     }
//     if (!GetUtils.isEmail(email)) {
//       emailError.value = 'Ingrese un correo electrónico válido';
//       return false;
//     }
//     emailError.value = '';
//     return true;
//   }

//   bool _validatePassword() {
//     final password = passwordController.text;

//     if (password.isEmpty) {
//       passwordError.value = 'La contraseña es obligatoria';
//       return false;
//     }

//     // Validar todos los requisitos
//     final validations = {
//       'length': password.length >= 8,
//       'uppercase': password.contains(RegExp(r'[A-Z]')),
//       'lowercase': password.contains(RegExp(r'[a-z]')),
//       'number': password.contains(RegExp(r'[0-9]')),
//       'special': password.contains(RegExp(r'[@$!%*?&]')),
//     };

//     passwordValidations.value = validations;

//     if (!validations.values.every((isValid) => isValid)) {
//       passwordError.value = 'La contraseña no cumple con todos los requisitos';
//       return false;
//     }

//     passwordError.value = '';
//     return true;
//   }

//   // Validar todos los campos
//   bool _validateAllFields() {
//     bool isValid = true;

//     if (!_validateName()) isValid = false;
//     if (!_validateLastname()) isValid = false;
//     if (!_validatePhone()) isValid = false;
//     if (!_validateEmail()) isValid = false;
//     if (!_validatePassword()) isValid = false;

//     return isValid;
//   }

//   // Registrar usuario
//   Future<void> registerUser() async {
//     if (isLoading.value) return;

//     if (!_validateAllFields()) {
//       _showSnackbar(
//         title: 'Error de validación',
//         message: 'Por favor, corrija los errores en el formulario',
//         color: Colors.red,
//       );
//       return;
//     }

//     isLoading.value = true;

//     try {
//       final result = await registerUseCase(
//         name: nameController.text.trim(),
//         lastname: lastnameController.text.trim(),
//         email: emailController.text.trim(),
//         phone: phoneController.text.trim(),
//         password: passwordController.text,
//       );

//       result.fold(
//         (failure) {
//           _showSnackbar(
//             title: 'Error en registro',
//             message: failure.message,
//             color: Colors.red,
//           );
//         },
//         (success) {
//           _showSnackbar(
//             title: 'Registro exitoso',
//             message: 'Usuario registrado correctamente',
//             color: Colors.green,
//           );

//           // Navegar a verificación de email o dashboard
//           Get.toNamed('/email-verification', arguments: {
//             'email': emailController.text.trim(),
//           });
//         },
//       );
//     } catch (e) {
//       _showSnackbar(
//         title: 'Error',
//         message: 'Error inesperado: ${e.toString()}',
//         color: Colors.red,
//       );
//     } finally {
//       isLoading.value = false;
//     }
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
//       duration: const Duration(seconds: 4),
//       icon: Icon(
//         color == Colors.green ? Icons.check_circle : Icons.error,
//         color: Colors.white,
//       ),
//     );
//   }
// }
