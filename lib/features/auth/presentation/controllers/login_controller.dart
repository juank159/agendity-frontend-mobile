import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:login_signup/features/auth/domain/failures/auth_failures.dart';
import 'package:login_signup/features/auth/domain/usecases/login_usecase.dart';
import 'package:login_signup/shared/widgets/app_snackbar.dart';
import 'auth_feedback.dart';
import 'auth_navigation.dart';

/// Login con email y contraseña (`/login`). La sesión la inicia el use case;
/// aquí solo se valida el formulario, se avisa del fallo según su tipo y se
/// entra a la home.
class LoginController extends GetxController {
  final LoginUseCase _login;

  LoginController({required LoginUseCase loginUseCase}) : _login = loginUseCase;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final isLoading = false.obs;
  final isPasswordHidden = true.obs;
  final emailError = ''.obs;
  final passwordError = ''.obs;

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  void togglePasswordVisibility() => isPasswordHidden.toggle();

  bool _validate() {
    final email = emailController.text.trim();
    emailError.value = email.isEmpty
        ? 'Ingresa tu correo electrónico'
        : (GetUtils.isEmail(email) ? '' : 'Ingresa un correo válido');
    passwordError.value =
        passwordController.text.isEmpty ? 'Ingresa tu contraseña' : '';
    return emailError.value.isEmpty && passwordError.value.isEmpty;
  }

  Future<void> loginUser() async {
    if (isLoading.value || !_validate()) return;
    isLoading.value = true;
    final result = await _login(LoginParams(
      email: emailController.text.trim(),
      password: passwordController.text,
    ));
    if (isClosed) return;

    await result.fold(
      (failure) async {
        isLoading.value = false;
        switch (failure) {
          case InvalidCredentialsFailure():
            passwordError.value = AuthFeedback.invalidCredentialsMessage;
          case InvalidAuthDataFailure():
            emailError.value = failure.message;
          default:
            break;
        }
        await AuthFeedback.show(failure, title: 'No se pudo iniciar sesión');
      },
      (user) async {
        final entered = await AuthNavigation.enterHome();
        if (entered) {
          AppSnackbar.success('Hola ${user.name}', title: '¡Bienvenido!');
        }
        if (!isClosed) isLoading.value = false;
      },
    );
  }
}
