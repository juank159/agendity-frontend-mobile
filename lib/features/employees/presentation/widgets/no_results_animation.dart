// Crear un archivo no_results_animation.dart
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:login_signup/core/constants/app_colors.dart';

class NoResultsAnimation extends StatelessWidget {
  final String message;
  final VoidCallback? onButtonPressed;
  final String buttonText;

  const NoResultsAnimation({
    Key? key,
    required this.message,
    this.onButtonPressed,
    this.buttonText = 'Limpiar búsqueda',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Nota: Necesitas agregar la dependencia lottie a tu pubspec.yaml
          // Si no quieres usarlo, puedes usar un simple Icon
          Lottie.asset(
            'assets/animations/no_results.json',
            width: 200,
            height: 200,
            repeat: true,
          ),
          // Alternativa sin Lottie:
          // const Icon(
          //   Icons.search_off,
          //   size: 80,
          //   color: Colors.grey,
          // ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          if (onButtonPressed != null)
            ElevatedButton.icon(
              onPressed: onButtonPressed,
              icon: const Icon(Icons.refresh),
              label: Text(buttonText),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cardIndicator,
                foregroundColor: Colors.white,
                elevation: 3,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
