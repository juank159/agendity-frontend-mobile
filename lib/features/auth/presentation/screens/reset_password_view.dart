import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/features/auth/presentation/controllers/reset_password_controller.dart';
import 'package:login_signup/shared/widgets/app_code_field.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/shared/widgets/app_note.dart';
import 'package:login_signup/shared/widgets/code_expiry_notice.dart';
import 'package:login_signup/features/auth/presentation/widgets/auth_layout.dart';
import 'package:login_signup/features/auth/presentation/widgets/auth_submit_button.dart';
import 'package:login_signup/features/auth/presentation/widgets/auth_text_field.dart';
import 'package:login_signup/features/auth/presentation/widgets/password_requirements_list.dart';

class ResetPasswordView extends GetView<ResetPasswordController> {
  const ResetPasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      title: 'Nueva contraseña',
      subtitle: 'Escribe el código que enviamos a:',
      subtitleTrailing: AuthEmailBadge(email: controller.email),
      logoHeight: 64,
      onBack: () => Get.back(),
      children: [
        Obx(() => AppCodeField(
              controller: controller.codeController,
              enabled: !controller.isLoading.value,
            )),
        Obx(() {
          final error = controller.codeError.value;
          if (error == null) return const SizedBox.shrink();
          return AppNote(error,
              tone: AppTone.error,
              icon: Icons.error_outline_rounded,
              margin: const EdgeInsets.only(top: 4, bottom: 8));
        }),
        Obx(() => controller.countdown.isActive
            ? CodeExpiryNotice(remaining: controller.countdown.formatted)
            : const SizedBox.shrink()),
        const SizedBox(height: 20),
        AuthTextField(
          controller: controller.passwordController,
          label: 'Nueva contraseña',
          hint: 'Mínimo 8 caracteres',
          icon: Icons.lock_rounded,
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
          icon: Icons.lock_rounded,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => controller.resetPassword(),
          error: controller.confirmPasswordError,
          obscure: controller.isConfirmPasswordHidden,
          onToggleObscure: controller.toggleConfirmPasswordVisibility,
        ),
        const SizedBox(height: 28),
        AuthSubmitButton(
          label: 'Cambiar contraseña',
          icon: Icons.lock_reset_rounded,
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
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reenviar código'),
            )),
      ],
    );
  }
}
