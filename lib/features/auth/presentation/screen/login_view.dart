import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/routes/routes.dart';
import 'package:login_signup/features/auth/presentation/controllers/login_controller.dart';
import '../widgets/button_global_form.dart';
import '../widgets/input_global_form.dart';
import '../widgets/social_media.dart';
import '../../../../utils/global_colors.dart';

class LoginView extends GetView<LoginController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: SafeArea(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(15.0),
            child: Form(
              key: controller.formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 50),

                  // Logo con animación
                  TweenAnimationBuilder(
                    duration: const Duration(milliseconds: 800),
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    builder: (context, double value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Container(
                          alignment: Alignment.center,
                          child: SvgPicture.asset(
                            'assets/images/logo.svg',
                            height: 100,
                            colorFilter: ColorFilter.mode(
                              GlobalColors.mainColor,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 50),

                  // Título con animación
                  FadeTransition(
                    opacity: Tween<double>(begin: 0, end: 1).animate(
                      CurvedAnimation(
                        parent: ModalRoute.of(context)!.animation!,
                        curve: const Interval(0.5, 1.0),
                      ),
                    ),
                    child: Text(
                      'Inicia sesión para comenzar',
                      style: TextStyle(
                        color: GlobalColors.textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Campo de correo electrónico
                  Obx(() => InputGlobalForm(
                        controller: controller.emailController,
                        text: 'Correo electrónico',
                        obscureText: false,
                        textInputType: TextInputType.emailAddress,
                        validator: controller.validateEmail,
                        errorText: controller.emailError.value,
                        suffixIcon: Icon(
                          Icons.email_outlined,
                          color: GlobalColors.mainColor,
                        ),
                      )),

                  const SizedBox(height: 16),

                  // Campo de contraseña
                  Obx(() => InputGlobalForm(
                        controller: controller.passwordController,
                        text: 'Contraseña',
                        obscureText: controller.isPasswordHidden.value,
                        textInputType: TextInputType.text,
                        validator: controller.validatePassword,
                        errorText: controller.passwordError.value,
                        suffixIcon: IconButton(
                          icon: Icon(
                            controller.isPasswordHidden.value
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: GlobalColors.mainColor,
                          ),
                          onPressed: controller.togglePasswordVisibility,
                        ),
                      )),

                  const SizedBox(height: 24),

                  // Botón de inicio de sesión
                  Obx(() => controller.isLoading.value
                      ? const Center(
                          child: CircularProgressIndicator(),
                        )
                      : ButtonGlobalForm(
                          textButton: 'Iniciar sesión',
                          onPressed: controller.loginUser,
                        )),

                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Get.toNamed(GetRoutes.forgotPassword),
                    child: Text(
                      '¿Olvidaste tu contraseña?',
                      style: TextStyle(
                        color: GlobalColors.mainColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 60),

                  // Inicio de sesión con redes sociales
                  const SocialMedia(
                    text: '- O inicia sesión con -',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),

      // Barra inferior para registro
      bottomNavigationBar: Container(
        height: 50,
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('¿No tienes una cuenta?'),
            const SizedBox(width: 5),
            InkWell(
              onTap: () => Get.toNamed(GetRoutes.register),
              child: Text(
                'Regístrate',
                style: TextStyle(
                  color: GlobalColors.mainColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
