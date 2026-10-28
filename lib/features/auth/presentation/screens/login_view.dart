import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/routes/routes.dart';
import 'package:login_signup/features/auth/presentation/controllers/login_controller.dart';
import 'package:login_signup/features/auth/presentation/widgets/auth_layout.dart';
import 'package:login_signup/features/auth/presentation/widgets/auth_submit_button.dart';
import 'package:login_signup/features/auth/presentation/widgets/auth_text_field.dart';
import 'package:login_signup/features/auth/presentation/widgets/google_sign_in_button.dart';

class LoginView extends GetView<LoginController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      title: '¡Bienvenido de vuelta!',
      subtitle: 'Inicia sesión para continuar',
      children: [
        AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthTextField(
                controller: controller.emailController,
                label: 'Correo electrónico',
                hint: 'tu@email.com',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                error: controller.emailError,
              ),
              const SizedBox(height: 16),
              AuthTextField(
                controller: controller.passwordController,
                label: 'Contraseña',
                icon: Icons.lock_outline,
                autofillHints: const [AutofillHints.password],
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => controller.loginUser(),
                error: controller.passwordError,
                obscure: controller.isPasswordHidden,
                onToggleObscure: controller.togglePasswordVisibility,
              ),
            ],
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => Get.toNamed(GetRoutes.forgotPassword),
            child: const Text('¿Olvidaste tu contraseña?'),
          ),
        ),
        const SizedBox(height: 8),
        AuthSubmitButton(
          label: 'Iniciar sesión',
          loading: controller.isLoading,
          onPressed: controller.loginUser,
        ),
        const SizedBox(height: 28),
        const GoogleSignInButton(dividerText: 'o inicia sesión con'),
        const SizedBox(height: 24),
        AuthFooterLink(
          question: '¿No tienes cuenta?',
          action: 'Regístrate',
          onTap: () => Get.toNamed(GetRoutes.register),
        ),
      ],
    );
  }
}
