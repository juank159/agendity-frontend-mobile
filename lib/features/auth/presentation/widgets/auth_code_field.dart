import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

/// Código de 6 dígitos enviado por email (verificación y recuperación). Su
/// vigencia se muestra con `CodeExpiryNotice` (shared). El [controller] lo
/// libera el GetxController dueño.
class AuthCodeField extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final ValueChanged<String>? onCompleted;

  const AuthCodeField({
    super.key,
    required this.controller,
    this.enabled = true,
    this.onCompleted,
  });

  static const length = 6;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return PinCodeTextField(
      appContext: context,
      controller: controller,
      // Lo libera el controller en onClose, no el campo.
      autoDisposeControllers: false,
      length: length,
      enabled: enabled,
      keyboardType: TextInputType.number,
      animationType: AnimationType.fade,
      enableActiveFill: true,
      textStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
      pinTheme: PinTheme(
        shape: PinCodeFieldShape.box,
        borderRadius: BorderRadius.circular(10),
        fieldHeight: 52,
        fieldWidth: 44,
        activeFillColor: scheme.surface,
        inactiveFillColor: scheme.surface,
        selectedFillColor: scheme.surface,
        activeColor: scheme.primary,
        inactiveColor: scheme.outlineVariant,
        selectedColor: scheme.primary,
      ),
      onChanged: (_) {},
      onCompleted: onCompleted,
    );
  }
}
