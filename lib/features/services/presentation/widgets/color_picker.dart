import 'package:flutter/material.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/shared/utils/color_hex.dart';

/// Colores que el Owner puede dar a un servicio en la agenda. Son datos del
/// negocio (se guardan como hex), no colores del tema.
const List<Color> servicePalette = [
  Color(0xFF2196F3),
  Color(0xFF4CAF50),
  Color(0xFFF44336),
  Color(0xFF009688),
  Color(0xFFFFC107),
  Color(0xFF3F51B5),
  Color(0xFF00BCD4),
  Color(0xFF9E9E9E),
  Color(0xFF673AB7),
  Color(0xFFCDDC39),
  Color(0xFF795548),
  Color(0xFFE91E63),
];

/// Selector del color de un servicio: muestras redondas con el degradado de
/// cada color; la elegida lleva un anillo del color primario y la marca. Si
/// el color actual no está en la paleta (servicios antiguos), se muestra al
/// principio para no perderlo. Cada muestra tiene la clave
/// `service-color-<hex>` (la usan los integration_test).
class ServiceColorPicker extends StatelessWidget {
  final Color selected;
  final ValueChanged<Color> onChanged;

  const ServiceColorPicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = context.tokens;
    final selectedHex = colorToHex(selected);
    final colors = [
      if (!servicePalette.any((c) => colorToHex(c) == selectedHex)) selected,
      ...servicePalette,
    ];
    final duration = AppMotion.of(context);
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final color in colors)
          Builder(builder: (context) {
            final hex = colorToHex(color);
            final isSelected = hex == selectedHex;
            return Semantics(
              button: true,
              selected: isSelected,
              label: 'Color $hex',
              child: InkWell(
                key: ValueKey('service-color-$hex'),
                customBorder: const CircleBorder(),
                onTap: () => onChanged(color),
                child: AnimatedContainer(
                  duration: duration,
                  curve: AppMotion.curve,
                  width: 44,
                  height: 44,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? scheme.primary
                          : scheme.surface.withValues(alpha: 0),
                      width: 2.5,
                    ),
                  ),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: tokens.gradientOf(color),
                      border: Border.all(color: tokens.innerBorder),
                      boxShadow: isSelected
                          ? tokens.elevation2(tint: color)
                          : tokens.elevation1(tint: color),
                    ),
                    child: isSelected
                        ? Icon(Icons.check_rounded,
                            color: contrastOn(color), size: 20)
                        : null,
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }
}
