import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/features/auth/presentation/controllers/reset_password_controller.dart';
import 'package:login_signup/features/auth/presentation/widgets/auth_code_field.dart';
import 'package:login_signup/features/auth/presentation/widgets/auth_layout.dart';
import 'package:login_signup/features/auth/presentation/widgets/auth_submit_button.dart';
import 'package:login_signup/features/auth/presentation/widgets/auth_text_field.dart';
import 'package:login_signup/features/auth/presentation/widgets/password_requirements_list.dart';

class ResetPasswordView extends GetView<ResetPasswordController> {
  const ResetPasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AuthLayout(
      title: 'Nueva contraseña',
      subtitle: 'Escribe el código que enviamos a:',
      subtitleTrailing: Text(
        controller.email,
        style: TextStyle(
          color: scheme.primary,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      logoHeight: 64,
      onBack: () => Get.back(),
      children: [
        Obx(() => AuthCodeField(
              controller: controller.codeController,
              enabled: !controller.isLoading.value,
            )),
        Obx(() {
          final error = controller.codeError.value;
          if (error == null) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(error,
                textAlign: TextAlign.center,
                style: TextStyle(color: scheme.error)),
          );
        }),
        Obx(() => controller.countdown.isActive
            ? CodeExpiryNotice(remaining: controller.countdown.formatted)
            : const SizedBox.shrink()),
        const SizedBox(height: 20),
        AuthTextField(
          controller: controller.passwordController,
          label: 'Nueva contraseña',
          hint: 'Mínimo 8 caracteres',
          icon: Icons.lock_outline,
          autofillHints: const [AutofillHints.newPassword],
          onChanged: controller.onPasswordChanged,
          error: controller.passwordError,
          obscure: controller.isPasswordHidden,
          onToggleObscure: controller.togglePasswordVisibility,
        ),
        PasswordRequirementsList(checks: controller.passwordChecks),
        const SizedBox(height: 16),
        AuthTextField(
          controller: controller.confirmPasswordController,
          label: 'Confirmar contraseña',
          hint: 'Repite la nueva contraseña',
          icon: Icons.lock_outline,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => controller.resetPassword(),
          error: controller.confirmPasswordError,
          obscure: controller.isConfirmPasswordHidden,
          onToggleObscure: controller.toggleConfirmPasswordVisibility,
        ),
        const SizedBox(height: 28),
        AuthSubmitButton(
          label: 'Cambiar contraseña',
          loading: controller.isLoading,
          onPressed: () {
            FocusScope.of(context).unfocus();
            controller.resetPassword();
          },
        ),
        const SizedBox(height: 12),
        Obx(() => TextButton.icon(
              onPressed:
                  controller.canResendCode ? controller.requestNewCode : null,
              icon: const Icon(Icons.refresh),
              label: const Text('Reenviar código'),
            )),
      ],
    );
  }
}
