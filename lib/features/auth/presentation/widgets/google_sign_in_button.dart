import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:login_signup/features/auth/presentation/controllers/google_auth_controller.dart';

/// Separador "o" + botón "Continuar con Google" del login y del registro.
/// El `GoogleAuthController` lo registra el binding de la ruta.
class GoogleSignInButton extends GetView<GoogleAuthController> {
  final String dividerText;

  const GoogleSignInButton({super.key, this.dividerText = 'o continúa con'});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(dividerText,
                  style: TextStyle(color: scheme.onSurfaceVariant)),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 52,
          child: Obx(() => OutlinedButton(
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: controller.isLoading.value
                    ? null
                    : controller.signInWithGoogle,
                child: controller.isLoading.value
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SvgPicture.asset('assets/images/google.svg',
                              height: 22, width: 22),
                          const SizedBox(width: 12),
                          const Text('Continuar con Google',
                              style: TextStyle(fontSize: 16)),
                        ],
                      ),
              )),
        ),
      ],
    );
  }
}
