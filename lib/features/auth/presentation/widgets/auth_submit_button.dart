import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/widgets/app_gradient_button.dart';

/// Botón principal de las pantallas de auth: el [AppGradientButton] de la
/// guía a todo el ancho, con la carga dentro del botón mientras [loading] es
/// `true`. [busy] (leído dentro del `Obx`) lo deshabilita también por otras
/// operaciones de la pantalla.
class AuthSubmitButton extends StatelessWidget {
  final String label;
  final RxBool loading;
  final bool Function()? busy;
  final VoidCallback onPressed;
  final IconData? icon;

  const AuthSubmitButton({
    super.key,
    required this.label,
    required this.loading,
    required this.onPressed,
    this.busy,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isLoading = loading.value;
      final blocked = busy?.call() ?? false;
      return AppGradientButton(
        label: label,
        icon: icon,
        expand: true,
        loading: isLoading,
        onPressed: isLoading || blocked ? null : onPressed,
      );
    });
  }
}
