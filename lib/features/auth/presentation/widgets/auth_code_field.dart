import 'package:flutter/material.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

/// Código de 6 dígitos enviado por email (verificación y recuperación), en
/// seis cajas con el estilo de los campos (relleno, radio 14): la caja activa
/// brilla con el color primario y las llenas toman el contenedor primario.
/// Su vigencia se muestra con `CodeExpiryNotice` (shared). El [controller] lo
/// libera el GetxController dueño.
///
/// Sigue siendo un `PinCodeTextField` (el integration_test escribe el código
/// en su `TextField`).
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = context.tokens;
    final empty =
        theme.inputDecorationTheme.fillColor ?? scheme.surfaceContainerHighest;
    return LayoutBuilder(builder: (context, constraints) {
      // Seis cajas con 8 px entre ellas, entre 40 y 52 de ancho.
      final width = ((constraints.maxWidth - 8 * (length - 1)) / length)
          .clamp(40.0, 52.0);
      // El TextField oculto del paquete heredaría el relleno de los campos
      // del tema (una banda bajo las cajas): aquí va sin relleno ni borde.
      return Theme(
        data: theme.copyWith(
          inputDecorationTheme: const InputDecorationTheme(
            filled: false,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
          ),
        ),
        child: PinCodeTextField(
          appContext: context,
          controller: controller,
          // Lo libera el controller en onClose, no el campo.
          autoDisposeControllers: false,
          length: length,
          enabled: enabled,
          keyboardType: TextInputType.number,
          animationType: AppMotion.enabled(context)
              ? AnimationType.scale
              : AnimationType.none,
          animationDuration: AppMotion.of(context, AppMotion.fast),
          enableActiveFill: true,
          cursorColor: scheme.primary,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          textStyle: theme.textTheme.headlineSmall
              ?.copyWith(
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              )
              .tabular,
          pinTheme: PinTheme(
            shape: PinCodeFieldShape.box,
            borderRadius: AppRadii.fieldRadius,
            fieldHeight: width * 1.2,
            fieldWidth: width,
            borderWidth: 1,
            selectedBorderWidth: 2,
            activeBorderWidth: 1.5,
            inactiveBorderWidth: 1,
            activeFillColor: scheme.primaryContainer,
            inactiveFillColor: empty,
            selectedFillColor: scheme.surface,
            disabledColor: scheme.outlineVariant.withValues(alpha: 0.4),
            activeColor: scheme.primary.withValues(alpha: 0.6),
            inactiveColor: scheme.outlineVariant,
            selectedColor: scheme.primary,
            errorBorderColor: scheme.error,
            activeBoxShadow: tokens.elevation1(tint: scheme.primary),
          ),
          onChanged: (_) {},
          onCompleted: onCompleted,
        ),
      );
    });
  }
}
