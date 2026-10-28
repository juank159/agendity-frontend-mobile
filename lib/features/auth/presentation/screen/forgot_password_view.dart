import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/features/auth/presentation/controllers/forgot_password_controller.dart';
import 'package:login_signup/features/auth/presentation/widgets/auth_layout.dart';
import 'package:login_signup/features/auth/presentation/widgets/auth_submit_button.dart';
import 'package:login_signup/features/auth/presentation/widgets/auth_text_field.dart';

class ForgotPasswordView extends GetView<ForgotPasswordController> {
  const ForgotPasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      title: 'Recuperar contraseña',
      subtitle: 'Escribe tu correo y te enviaremos un código para crear una '
          'contraseña nueva.',
      onBack: () => Get.back(),
      children: [
        AuthTextField(
          controller: controller.emailController,
          label: 'Correo electrónico',
          hint: 'tu@email.com',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => controller.requestPasswordReset(),
          error: controller.emailError,
        ),
        const SizedBox(height: 28),
        AuthSubmitButton(
          label: 'Enviar código',
          loading: controller.isLoading,
          onPressed: controller.requestPasswordReset,
        ),
        const SizedBox(height: 16),
        AuthFooterLink(
          question: '¿Recordaste tu contraseña?',
          action: 'Inicia sesión',
          onTap: () => Get.back(),
        ),
      ],
    );
  }
}
