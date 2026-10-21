import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/features/auth/presentation/controllers/google_auth_controller.dart';
import 'package:login_signup/features/auth/presentation/widgets/icon_social_media_form.dart';
import 'package:login_signup/utils/global_colors.dart';

class SocialMedia extends StatelessWidget {
  final String text;
  const SocialMedia({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Divisor con texto mejorado
        _buildDividerWithText(),
        const SizedBox(height: 24),
        // Botones de redes sociales
        _buildSocialButtons(),
      ],
    );
  }

  // Divisor con texto estilizado
  Widget _buildDividerWithText() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.grey[300]!,
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            text,
            style: TextStyle(
              color: GlobalColors.textColor.withOpacity(0.6),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.grey[300]!,
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Botones de redes sociales
  Widget _buildSocialButtons() {
    return SizedBox(
      width: double.infinity,
      child: Row(
        children: [
          // Google sign in - CON funcionalidad
          _buildGoogleButton(),

          const SizedBox(width: 12),

          // Facebook - SIN funcionalidad (próximamente)
          IconSocialMediaForm(
            path: 'assets/images/facebook.svg',
            label: 'Facebook',
            onTap: () => _showComingSoonSnackbar('Facebook', Colors.black),
          ),

          const SizedBox(width: 12),

          // Apple - SIN funcionalidad (próximamente)
          IconSocialMediaForm(
            path: 'assets/images/apple.svg',
            label: 'Apple',
            onTap: () => _showComingSoonSnackbar('Apple', Colors.black),
          ),
        ],
      ),
    );
  }

  // Botón de Google con funcionalidad real
  Widget _buildGoogleButton() {
    try {
      // Intentar obtener el controlador
      final GoogleAuthController googleAuthController =
          Get.find<GoogleAuthController>();

      return Obx(() => IconSocialMediaForm(
            path: 'assets/images/google.svg',
            label: 'Google',
            onTap: googleAuthController.signInWithGoogle,
            isLoading: googleAuthController.isLoading.value,
          ));
    } catch (e) {
      // Si no existe el controlador, mostrar botón sin funcionalidad
      debugPrint('⚠️ GoogleAuthController no encontrado: $e');
      return IconSocialMediaForm(
        path: 'assets/images/google.svg',
        label: 'Google',
        onTap: () => _showComingSoonSnackbar('Google', Colors.red),
      );
    }
  }

  // Mostrar snackbar de "próximamente"
  void _showComingSoonSnackbar(String platform, Color color) {
    Get.snackbar(
      'Próximamente',
      'Inicio de sesión con $platform estará disponible pronto',
      snackPosition: SnackPosition.TOP,
      backgroundColor: color.withOpacity(0.1),
      colorText: color,
      icon: Icon(Icons.info_outline, color: color),
      duration: const Duration(seconds: 2),
    );
  }
}
