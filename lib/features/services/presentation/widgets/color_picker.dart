import 'package:flutter/material.dart';
import 'package:login_signup/features/services/domain/entities/service_entity.dart';

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

/// `Color` → `#rrggbb` (lo que guarda `ServiceEntity.color`).
String colorToHex(Color color) =>
    '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

/// `#rrggbb` o `#rgb` → `Color`. Un valor inválido da el color por defecto
/// del servicio.
Color colorFromHex(String hex) {
  var digits = hex.trim().replaceFirst('#', '');
  if (digits.length == 3) {
    digits = digits.split('').map((c) => '$c$c').join();
  }
  final value = digits.length == 6 ? int.tryParse(digits, radix: 16) : null;
  if (value == null) return colorFromHex(ServiceEntity.defaultColor);
  return Color(0xFF000000 | value);
}

/// Selector del color de un servicio. Si el color actual no está en la
/// paleta (servicios antiguos), se muestra al principio para no perderlo.
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
    final selectedHex = colorToHex(selected);
    final colors = [
      if (!servicePalette.any((c) => colorToHex(c) == selectedHex)) selected,
      ...servicePalette,
    ];
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final color in colors)
          Semantics(
            button: true,
            selected: colorToHex(color) == selectedHex,
            label: 'Color ${colorToHex(color)}',
            child: InkWell(
              key: ValueKey('service-color-${colorToHex(color)}'),
              customBorder: const CircleBorder(),
              onTap: () => onChanged(color),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: colorToHex(color) == selectedHex
                      ? Border.all(color: scheme.onSurface, width: 3)
                      : null,
                ),
                child: colorToHex(color) == selectedHex
                    ? Icon(Icons.check, color: _contrastOn(color), size: 20)
                    : null,
              ),
            ),
          ),
      ],
    );
  }

  /// Blanco o negro, lo que se lea mejor sobre [color].
  static Color _contrastOn(Color color) =>
      ThemeData.estimateBrightnessForColor(color) == Brightness.dark
          ? const Color(0xFFFFFFFF)
          : const Color(0xFF000000);
}
