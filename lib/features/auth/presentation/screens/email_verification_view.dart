import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/features/auth/presentation/controllers/email_verification_controller.dart';
import 'package:login_signup/features/auth/presentation/widgets/auth_code_field.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/shared/widgets/app_note.dart';
import 'package:login_signup/shared/widgets/code_expiry_notice.dart';
import 'package:login_signup/features/auth/presentation/widgets/auth_layout.dart';
import 'package:login_signup/features/auth/presentation/widgets/auth_submit_button.dart';

/// Verificación del correo tras registrarse. El Owner puede entrar sin
/// verificar ("Verificar más tarde").
class EmailVerificationView extends GetView<EmailVerificationController> {
  const EmailVerificationView({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      title: 'Verifica tu correo',
      subtitle: 'Escribe el código de 6 dígitos que enviamos a:',
      subtitleTrailing: AuthEmailBadge(email: controller.email),
      children: [
        Obx(() {
          final message = controller.errorMessage.value;
          if (message == null) return const SizedBox.shrink();
          return AppNote(message,
              tone: AppTone.error,
              icon: Icons.error_outline_rounded,
              margin: const EdgeInsets.only(bottom: 16));
        }),
        AuthCodeField(
          controller: controller.codeController,
          onCompleted: (_) => controller.verifyEmail(),
        ),
        Obx(() => controller.countdown.isActive
            ? CodeExpiryNotice(remaining: controller.countdown.formatted)
            : const SizedBox.shrink()),
        const SizedBox(height: 24),
        AuthSubmitButton(
          label: 'Verificar correo',
          icon: Icons.verified_rounded,
          loading: controller.isVerifying,
          busy: () => controller.isBusy,
          onPressed: controller.verifyEmail,
        ),
        const SizedBox(height: 8),
        const SizedBox(height: 4),
        Obx(() => TextButton.icon(
              onPressed:
                  controller.isBusy ? null : controller.requestVerificationCode,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reenviar código'),
            )),
        TextButton(
          onPressed: controller.skip,
          child: const Text('Verificar más tarde'),
        ),
      ],
    );
  }
}
