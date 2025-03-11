import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:login_signup/features/auth/presentation/controllers/google_auth_controller.dart';

class GoogleSignInButton extends StatelessWidget {
  final String text;
  final double width;
  final double height;
  final double borderRadius;

  const GoogleSignInButton({
    Key? key,
    this.text = 'Continuar con Google',
    this.width = double.infinity,
    this.height = 50,
    this.borderRadius = 8,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<GoogleAuthController>();

    return Obx(() {
      return SizedBox(
        width: width,
        height: height,
        child: ElevatedButton(
          onPressed:
              controller.isLoading.value ? null : controller.signInWithGoogle,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            elevation: 1,
            side: const BorderSide(color: Colors.grey, width: 0.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
          ),
          child: controller.isLoading.value
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo de Google
                    SvgPicture.asset(
                      'assets/icons/google_logo.svg',
                      height: 24,
                      width: 24,
                    ),
                    const SizedBox(width: 12),
                    // Texto del botón
                    Text(
                      text,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
        ),
      );
    });
  }
}
