import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/routes/routes.dart';
import 'package:login_signup/features/auth/domain/usecases/request_password_reset_usecase.dart';
import 'package:login_signup/features/auth/domain/usecases/reset_password_usecase.dart';
import 'package:login_signup/shared/widgets/app_snackbar.dart';
import 'auth_feedback.dart';
import 'auth_navigation.dart';
import 'package:login_signup/shared/controller/code_countdown.dart';
import 'password_policy.dart';

/// Cambia la contraseña con el código de recuperación (`/reset-password`,
/// email en `arguments`). Al terminar vuelve al login.
class ResetPasswordController extends GetxController {
  final ResetPasswordUseCase _reset;
  final RequestPasswordResetUseCase _requestCode;

  ResetPasswordController({
    required ResetPasswordUseCase resetPasswordUseCase,
    required RequestPasswordResetUseCase requestPasswordResetUseCase,
    String? email,
  })  : _reset = resetPasswordUseCase,
        _requestCode = requestPasswordResetUseCase,
        email = email ?? AuthNavigation.emailArgument();

  static const codeLength = 6;

  final String email;

  final codeController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final isLoading = false.obs;
  final isPasswordHidden = true.obs;
  final isConfirmPasswordHidden = true.obs;

  final codeError = RxnString();
  final passwordError = ''.obs;
  final confirmPasswordError = ''.obs;

  /// Estado de cada requisito; vacío hasta que se escribe la contraseña.
  final passwordChecks = <PasswordRequirement, bool>{}.obs;

  late final countdown = CodeCountdown(
    onExpired: () => codeError.value = 'El código venció. Pide uno nuevo.',
  );

  bool get canResendCode => !countdown.isActive && !isLoading.value;

  @override
  void onInit() {
    super.onInit();
    // El código lo acaba de enviar la pantalla anterior.
    if (email.isNotEmpty) countdown.start();
  }

  @override
  void onClose() {
    countdown.dispose();
    codeController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }

  void togglePasswordVisibility() => isPasswordHidden.toggle();

  void toggleConfirmPasswordVisibility() => isConfirmPasswordHidden.toggle();

  void onPasswordChanged(String password) {
    passwordChecks.assignAll(PasswordPolicy.check(password));
    if (passwordError.value.isNotEmpty &&
        PasswordPolicy.validate(password) == null) {
      passwordError.value = '';
    }
  }

  bool _validate() {
    final password = passwordController.text;
    final confirm = confirmPasswordController.text;
    codeError.value = codeController.text.trim().length == codeLength
        ? null
        : 'Ingresa los $codeLength dígitos del código';
    passwordChecks.assignAll(PasswordPolicy.check(password));
    passwordError.value = PasswordPolicy.validate(password) ?? '';
    confirmPasswordError.value = confirm.isEmpty
        ? 'Confirma tu nueva contraseña'
        : (confirm == password ? '' : 'Las contraseñas no coinciden');
    return codeError.value == null &&
        passwordError.value.isEmpty &&
        confirmPasswordError.value.isEmpty;
  }

  Future<void> requestNewCode() async {
    if (!canResendCode || email.isEmpty) return;
    isLoading.value = true;
    final result = await _requestCode(email);
    if (isClosed) return;
    isLoading.value = false;
    await result.fold(
      (failure) => AuthFeedback.show(failure,
          title: 'No se pudo enviar el código'),
      (_) async {
        codeError.value = null;
        countdown.start();
        AppSnackbar.info('Te enviamos un código nuevo a $email',
            title: 'Código enviado');
      },
    );
  }

  Future<void> resetPassword() async {
    if (isLoading.value || !_validate()) return;
    isLoading.value = true;
    final result = await _reset(ResetPasswordParams(
      email: email,
      code: codeController.text,
      newPassword: passwordController.text,
    ));
    if (isClosed) return;
    isLoading.value = false;
    await result.fold(
      (failure) async {
        if (failure is InvalidVerificationCodeFailure) {
          codeError.value = failure.message;
          return;
        }
        await AuthFeedback.show(failure,
            title: 'No se pudo cambiar la contraseña');
      },
      (_) async {
        countdown.stop();
        Get.offAllNamed(GetRoutes.login);
        AppSnackbar.success('Inicia sesión con tu nueva contraseña',
            title: 'Contraseña actualizada');
      },
    );
  }
}
