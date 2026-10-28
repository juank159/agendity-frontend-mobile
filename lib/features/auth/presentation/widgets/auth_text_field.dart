import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Campo de texto de las pantallas de auth. El error viene del controller
/// ([error] vacío = sin error) y se pinta con los colores del tema.
class AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData icon;
  final RxString? error;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;

  /// Si no es `null`, el campo es de contraseña: oculta el texto mientras el
  /// valor sea `true` y muestra el botón de ver/ocultar.
  final RxBool? obscure;
  final VoidCallback? onToggleObscure;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.hint,
    this.error,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.autofillHints,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.obscure,
    this.onToggleObscure,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final hidden = obscure?.value ?? false;
      final message = error?.value ?? '';
      return TextField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        autofillHints: autofillHints,
        obscureText: hidden,
        enableSuggestions: obscure == null,
        autocorrect: obscure == null,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon),
          suffixIcon: obscure == null
              ? null
              : IconButton(
                  tooltip: hidden ? 'Mostrar contraseña' : 'Ocultar contraseña',
                  icon: Icon(hidden
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined),
                  onPressed: onToggleObscure,
                ),
          errorText: message.isEmpty ? null : message,
          errorMaxLines: 3,
          filled: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    });
  }
}
