// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:login_signup/features/auth/domain/usecases/login_usecase.dart';
// import 'package:login_signup/features/auth/presentation/controllers/user_info_controller.dart';
// import 'package:login_signup/shared/local_storage/local_storage.dart';

// import '../widgets/custom_dialog.dart';
// import '../../../../core/errors/failures.dart';

// class LoginController extends GetxController {
//   final LoginUseCase _loginUseCase;

//   LoginController({required LoginUseCase loginUseCase})
//       : _loginUseCase = loginUseCase;

//   // Controllers
//   final emailController = TextEditingController();
//   final passwordController = TextEditingController();

//   // Observables
//   final isLoading = false.obs;
//   final isPasswordHidden = true.obs;
//   final emailError = RxnString();
//   final passwordError = RxnString();

//   // Form
//   final formKey = GlobalKey<FormState>();

//   @override
//   void onInit() {
//     super.onInit();
//     // Limpiamos errores cuando el usuario empiece a escribir
//     emailController.addListener(() => emailError.value = null);
//     passwordController.addListener(() => passwordError.value = null);
//   }

//   @override
//   void onClose() {
//     emailController.dispose();
//     passwordController.dispose();
//     super.onClose();
//   }

//   void togglePasswordVisibility() {
//     isPasswordHidden.value = !isPasswordHidden.value;
//   }

//   String? validateEmail(String? value) {
//     if (value == null || value.isEmpty) {
//       emailError.value = 'El correo es requerido';
//       return emailError.value;
//     }
//     if (!GetUtils.isEmail(value)) {
//       emailError.value = 'Ingrese un correo válido';
//       return emailError.value;
//     }
//     emailError.value = null;
//     return null;
//   }

//   String? validatePassword(String? value) {
//     if (value == null || value.isEmpty) {
//       passwordError.value = 'La contraseña es requerida';
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
//     // Validar el formulario
//     if (!formKey.currentState!.validate()) {
//       _showErrorDialog('Por favor, complete todos los campos correctamente');
//       return;
//     }

//     try {
//       isLoading.value = true;

//       final result = await _loginUseCase(
//         email: emailController.text.trim(),
//         password: passwordController.text,
//       );

//       result.fold(
//         (failure) => _handleFailure(failure),
//         (user) => _handleSuccess(),
//       );
//     } catch (e) {
//       _showErrorDialog('Error inesperado: ${e.toString()}');
//     } finally {
//       isLoading.value = false;
//     }
//   }

//   void _handleFailure(Failure failure) {
//     String errorMessage = _mapFailureToMessage(failure);
//     _showErrorDialog(errorMessage);
//   }

//   void _handleSuccess() async {
//     try {
//       final result = await _loginUseCase(
//         email: emailController.text.trim(),
//         password: passwordController.text,
//       );

//       result.fold(
//         (failure) => _handleFailure(failure),
//         (userEntity) async {
//           try {
//             // Guardar los datos del usuario
//             await Get.find<LocalStorage>()
//                 .saveUserData('userId', userEntity.id);

//             // Inicializar o actualizar UserInfoController
//             if (!Get.isRegistered<UserInfoController>()) {
//               Get.put(UserInfoController());
//             } else {
//               // Recargar la información si ya existe el controlador
//               await Get.find<UserInfoController>().loadUserInfo();
//             }

//             clearInputs();
//             Get.offAllNamed('/home');
//           } catch (e) {
//             _showErrorDialog('Error al procesar la información del usuario');
//           }
//         },
//       );
//     } catch (e) {
//       _showErrorDialog('Error inesperado durante el inicio de sesión');
//     }
//   }

//   String _mapFailureToMessage(Failure failure) {
//     if (failure is ServerFailure) {
//       if (failure.message.contains('401')) {
//         return 'Credenciales incorrectas. Por favor, verifica tu correo y contraseña';
//       }
//       if (failure.message.contains('404')) {
//         return 'Usuario no encontrado. ¿Estás registrado?';
//       }
//       if (failure.message.contains('429')) {
//         return 'Demasiados intentos. Por favor, espera unos minutos';
//       }
//       if (failure.message.contains('500')) {
//         return 'Error en el servidor. Por favor, inténtalo más tarde';
//       }
//       return 'Error de conexión. Verifica tu conexión a internet';
//     }
//     return 'Error inesperado. Por favor, inténtalo de nuevo';
//   }

//   void _showErrorDialog(String message) {
//     CustomDialog.show(
//       title: 'Error de inicio de sesión',
//       message: message,
//       type: DialogType.error,
//     );
//   }

//   void clearInputs() {
//     emailController.clear();
//     passwordController.clear();
//     emailError.value = null;
//     passwordError.value = null;
//   }

//   // Método para pruebas y depuración
//   bool isValidEmail(String email) => GetUtils.isEmail(email);
//   bool isValidPassword(String password) => password.length >= 6;
// }

import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
    final emailValid = validateEmail(emailController.text) == null;
    final passwordValid = validatePassword(passwordController.text) == null;

    if (!emailValid || !passwordValid) {
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
          isLoading.value = false;
          Get.snackbar(
            'Error',
            failure.message,
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.red.withOpacity(0.9),
            colorText: Colors.white,
            margin: const EdgeInsets.all(15),
            borderRadius: 8,
          );
        },
        (user) {
          isLoading.value = false;
          Get.offAllNamed('/');
        },
      );
    } catch (e) {
      isLoading.value = false;
      Get.snackbar(
        'Error',
        'Ha ocurrido un error inesperado',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.withOpacity(0.9),
        colorText: Colors.white,
        margin: const EdgeInsets.all(15),
        borderRadius: 8,
      );
    }
  }
}
