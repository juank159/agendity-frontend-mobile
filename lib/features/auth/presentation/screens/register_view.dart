import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/features/auth/presentation/controllers/register_controller.dart';
import 'package:login_signup/features/auth/presentation/widgets/auth_layout.dart';
import 'package:login_signup/features/auth/presentation/widgets/auth_submit_button.dart';
import 'package:login_signup/features/auth/presentation/widgets/auth_text_field.dart';
import 'package:login_signup/features/auth/presentation/widgets/google_sign_in_button.dart';
import 'package:login_signup/features/auth/presentation/widgets/password_requirements_list.dart';

/// Alta de un negocio: datos del Owner. Al crear la cuenta pasa a verificar
/// el correo.
class RegisterView extends GetView<RegisterController> {
  const RegisterView({super.key});

  static const _gap = SizedBox(height: 14);

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      title: 'Crea tu cuenta',
      subtitle: 'Registra tu negocio y empieza tu periodo de prueba',
      logoHeight: 64,
      children: [
        AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthTextField(
                controller: controller.nameController,
                label: 'Nombre',
                hint: 'Tu nombre',
                icon: Icons.person_outline,
                autofillHints: const [AutofillHints.givenName],
                error: controller.nameError,
              ),
              _gap,
              AuthTextField(
                controller: controller.lastnameController,
                label: 'Apellidos',
                hint: 'Tus apellidos',
                icon: Icons.person_outline,
                autofillHints: const [AutofillHints.familyName],
                error: controller.lastnameError,
              ),
              _gap,
              AuthTextField(
                controller: controller.businessNameController,
                label: 'Nombre del negocio (opcional)',
                hint: 'Ej.: Cejas y Pestañas Luna',
                icon: Icons.storefront_outlined,
                autofillHints: const [AutofillHints.organizationName],
                error: controller.businessNameError,
              ),
              _gap,
              AuthTextField(
                controller: controller.phoneController,
                label: 'Teléfono',
                hint: '3001234567',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                autofillHints: const [AutofillHints.telephoneNumber],
                error: controller.phoneError,
              ),
              _gap,
              AuthTextField(
                controller: controller.emailController,
                label: 'Correo electrónico',
                hint: 'tu@email.com',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                error: controller.emailError,
              ),
              _gap,
              AuthTextField(
                controller: controller.passwordController,
                label: 'Contraseña',
                hint: 'Mínimo 8 caracteres',
                icon: Icons.lock_outline,
                autofillHints: const [AutofillHints.newPassword],
                textInputAction: TextInputAction.done,
                onChanged: controller.onPasswordChanged,
                error: controller.passwordError,
                obscure: controller.isPasswordHidden,
                onToggleObscure: controller.togglePasswordVisibility,
              ),
              PasswordRequirementsList(checks: controller.passwordChecks),
            ],
          ),
        ),
        const SizedBox(height: 24),
        AuthSubmitButton(
          label: 'Crear cuenta',
          loading: controller.isLoading,
          onPressed: controller.registerUser,
        ),
        const SizedBox(height: 24),
        const GoogleSignInButton(dividerText: 'o regístrate con'),
        const SizedBox(height: 16),
        AuthFooterLink(
          question: '¿Ya tienes una cuenta?',
          action: 'Inicia sesión',
          onTap: () => Get.back(),
        ),
      ],
    );
  }
}
