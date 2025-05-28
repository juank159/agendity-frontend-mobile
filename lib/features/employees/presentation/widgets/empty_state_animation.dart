// Crear archivo empty_state_animation.dart
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:login_signup/core/constants/app_colors.dart';

class EmptyStateAnimation extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onActionPressed;
  final String actionText;
  final String? animationAsset;

  const EmptyStateAnimation({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.onActionPressed,
    required this.actionText,
    this.animationAsset = 'assets/animations/empty_state.json',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Usar Lottie si está disponible, de lo contrario usar un ícono
          if (animationAsset != null)
            Lottie.asset(
              animationAsset!,
              width: 200,
              height: 200,
              repeat: true,
            )
          else
            const Icon(
              Icons.people_outline,
              size: 100,
              color: Colors.grey,
            ),
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              subtitle,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: onActionPressed,
            icon: const Icon(Icons.add),
            label: Text(actionText),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.cardIndicator,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
