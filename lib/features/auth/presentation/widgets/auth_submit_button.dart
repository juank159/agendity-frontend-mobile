import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Botón principal de las pantallas de auth: deshabilitado y con indicador
/// mientras [loading] es `true`. [busy] (leído dentro del `Obx`) lo
/// deshabilita también por otras operaciones de la pantalla.
class AuthSubmitButton extends StatelessWidget {
  final String label;
  final RxBool loading;
  final bool Function()? busy;
  final VoidCallback onPressed;

  const AuthSubmitButton({
    super.key,
    required this.label,
    required this.loading,
    required this.onPressed,
    this.busy,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: Obx(() => FilledButton(
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              textStyle:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            onPressed:
                loading.value || (busy?.call() ?? false) ? null : onPressed,
            child: loading.value
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(label),
          )),
    );
  }
}
