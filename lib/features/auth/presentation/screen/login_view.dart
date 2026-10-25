import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/routes/routes.dart';
import 'package:login_signup/features/auth/presentation/controllers/login_controller.dart';
import 'package:login_signup/features/auth/presentation/widgets/social_media.dart';
import '../../../../utils/global_colors.dart';

class LoginView extends GetView<LoginController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: _buildBackgroundDecoration(),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                _buildLogo(),
                const SizedBox(height: 25),
                _buildWelcomeText(),
                const SizedBox(height: 38),
                _buildEmailField(),
                const SizedBox(height: 24),
                _buildPasswordField(),
                const SizedBox(height: 10),
                _buildForgotPasswordButton(),
                const SizedBox(height: 22),
                _buildLoginButton(),
                const SizedBox(height: 28),
                // Widget de redes sociales
                const SocialMedia(text: 'O inicia sesión con'),
                const SizedBox(height: 32),
                _buildRegisterButton(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Decoración del fondo
  BoxDecoration _buildBackgroundDecoration() {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          GlobalColors.mainColor.withValues(alpha: 0.1),
          Colors.white,
          Colors.white,
        ],
      ),
    );
  }

  // Logo principal
  Widget _buildLogo() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(10),
        // decoration: BoxDecoration(
        //   color: Colors.white,
        //   borderRadius: BorderRadius.circular(20),
        //   boxShadow: [
        //     BoxShadow(
        //       color: GlobalColors.mainColor.withOpacity(0.1),
        //       spreadRadius: 0,
        //       blurRadius: 20,
        //       offset: const Offset(0, 10),
        //     ),
        //   ],
        // ),
        child: SvgPicture.asset(
          'assets/images/logo.svg',
          height: 75,
          colorFilter: ColorFilter.mode(
            GlobalColors.mainColor,
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }

  // Texto de bienvenida
  Widget _buildWelcomeText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '¡Bienvenido de vuelta! 👋',
          style: TextStyle(
            color: GlobalColors.textColor,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Inicia sesión para continuar',
          style: TextStyle(
            color: GlobalColors.textColor.withValues(alpha: 0.6),
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  // Campo de email
  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('Correo electrónico'),
        const SizedBox(height: 12),
        TextField(
          controller: controller.emailController,
          keyboardType: TextInputType.emailAddress,
          style: _buildInputTextStyle(),
          decoration: _buildInputDecoration(
            hintText: 'tu@email.com',
            prefixIcon: Icons.email_outlined,
          ),
        ),
        _buildErrorMessage(controller.emailError),
      ],
    );
  }

  // Campo de contraseña
  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('Contraseña'),
        const SizedBox(height: 12),
        Obx(() => TextField(
              controller: controller.passwordController,
              obscureText: controller.isPasswordHidden.value,
              style: _buildInputTextStyle(),
              decoration: _buildInputDecoration(
                hintText: 'Tu contraseña',
                prefixIcon: Icons.lock_outline,
                suffixIcon: IconButton(
                  icon: Icon(
                    controller.isPasswordHidden.value
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: GlobalColors.mainColor,
                    size: 22,
                  ),
                  onPressed: controller.togglePasswordVisibility,
                ),
              ),
            )),
        _buildErrorMessage(controller.passwordError),
      ],
    );
  }

  // Etiqueta para campos
  Widget _buildFieldLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        color: GlobalColors.textColor,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  // Estilo de texto para inputs
  TextStyle _buildInputTextStyle() {
    return TextStyle(
      color: GlobalColors.textColor,
      fontSize: 16,
    );
  }

  // Decoración para inputs
  InputDecoration _buildInputDecoration({
    required String hintText,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        color: GlobalColors.textColor.withValues(alpha: 0.5),
      ),
      prefixIcon: Icon(
        prefixIcon,
        color: GlobalColors.mainColor,
        size: 22,
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: GlobalColors.mainColor.withValues(alpha: 0.05),
      border: _buildInputBorder(GlobalColors.mainColor.withValues(alpha: 0.2), 1),
      enabledBorder:
          _buildInputBorder(GlobalColors.mainColor.withValues(alpha: 0.2), 1),
      focusedBorder: _buildInputBorder(GlobalColors.mainColor, 2),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
    );
  }

  // Borde para inputs
  OutlineInputBorder _buildInputBorder(Color color, double width) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  // Mensaje de error
  Widget _buildErrorMessage(RxString errorMessage) {
    return Obx(() => errorMessage.value.isNotEmpty
        ? Padding(
            padding: const EdgeInsets.only(top: 8, left: 16),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 16),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    errorMessage.value,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              ],
            ),
          )
        : const SizedBox.shrink());
  }

  // Botón de olvidar contraseña
  Widget _buildForgotPasswordButton() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () => Get.toNamed(GetRoutes.forgotPassword),
        child: Text(
          '¿Olvidaste tu contraseña?',
          style: TextStyle(
            color: GlobalColors.mainColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // Botón principal de login
  Widget _buildLoginButton() {
    return Obx(() => Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                GlobalColors.mainColor,
                GlobalColors.mainColor.withValues(alpha: 0.8),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: GlobalColors.mainColor.withValues(alpha: 0.3),
                spreadRadius: 0,
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: controller.isLoading.value ? null : controller.loginUser,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: controller.isLoading.value
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Iniciar sesión',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ));
  }

  // Botón de registro
  Widget _buildRegisterButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '¿No tienes cuenta? ',
          style: TextStyle(
            color: GlobalColors.textColor.withValues(alpha: 0.7),
            fontSize: 16,
          ),
        ),
        GestureDetector(
          onTap: () => Get.toNamed(GetRoutes.register),
          child: Text(
            'Regístrate',
            style: TextStyle(
              color: GlobalColors.mainColor,
              // fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
