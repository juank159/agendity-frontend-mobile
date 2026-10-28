import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/routes/routes.dart';
import 'package:login_signup/features/auth/domain/usecases/request_password_reset_usecase.dart';
import 'package:login_signup/shared/widgets/app_snackbar.dart';
import 'auth_feedback.dart';
import 'auth_navigation.dart';

/// Pide el código de recuperación (`/forgot-password`) y abre
/// `/reset-password` con el email.
class ForgotPasswordController extends GetxController {
  final RequestPasswordResetUseCase _requestReset;

  ForgotPasswordController(
      {required RequestPasswordResetUseCase requestPasswordResetUseCase})
      : _requestReset = requestPasswordResetUseCase;

  final emailController = TextEditingController();
  final isLoading = false.obs;
  final emailError = ''.obs;

  @override
  void onClose() {
    emailController.dispose();
    super.onClose();
  }

  Future<void> requestPasswordReset() async {
    if (isLoading.value) return;
    final email = emailController.text.trim();
    emailError.value = email.isEmpty
        ? 'Ingresa tu correo electrónico'
        : (GetUtils.isEmail(email) ? '' : 'Ingresa un correo válido');
    if (emailError.value.isNotEmpty) return;

    isLoading.value = true;
    final result = await _requestReset(email);
    if (isClosed) return;
    isLoading.value = false;
    await result.fold(
      (failure) => AuthFeedback.show(failure,
          title: 'No se pudo enviar el código'),
      (_) async {
        AppSnackbar.success('Te enviamos un código de recuperación a $email',
            title: 'Código enviado');
        Get.toNamed(GetRoutes.resetPassword,
            arguments: {AuthNavigation.emailKey: email});
      },
    );
  }
}
