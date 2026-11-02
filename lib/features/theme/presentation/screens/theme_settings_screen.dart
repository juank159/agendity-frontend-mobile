import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/common/enums/appointment_status_enum.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/core/utils/formatters.dart';
import 'package:login_signup/core/widgets/app_gradient_button.dart';
import 'package:login_signup/features/theme/domain/entities/theme_preference.dart';
import 'package:login_signup/shared/controllers/theme_controller.dart';
import 'package:login_signup/shared/widgets/app_avatar.dart';
import 'package:login_signup/shared/widgets/app_card.dart';
import 'package:login_signup/shared/widgets/app_section_header.dart';
import 'package:login_signup/shared/widgets/palette_swatch.dart';
import 'package:login_signup/shared/widgets/status_chip.dart';

/// "Apariencia" (D-22): vista previa en vivo, color de **este dispositivo**
/// (muestras de las 6 paletas o "Usar el del negocio") y modo (claro, oscuro,
/// sistema o alto contraste). Lo elegido aquí manda sobre el color del
/// negocio, solo en este teléfono. Cualquier rol.
class ThemeSettingsScreen extends GetView<ThemeController> {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Apariencia')),
      body: Obx(() {
        final usesBusiness = controller.usesBusinessPalette;
        final selected = controller.preference.value.palette;
        final business = controller.businessPalette.value;
        final mode = controller.mode;
        return ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            const AppSectionHeader(
              title: 'Vista previa',
              icon: Icons.visibility_rounded,
            ),
            const _LivePreview(),
            const AppSectionHeader(
              title: 'Color',
              subtitle: 'Solo en este teléfono. El del negocio lo elige el '
                  'propietario en Mi negocio.',
              icon: Icons.palette_rounded,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _BusinessPaletteOption(
                business: business ?? AppPalette.fallback,
                selected: usesBusiness,
                onTap: () => controller.setPalette(null),
              ),
            ),
            const SizedBox(height: 12),
            PaletteSwatchGrid(
              selected: usesBusiness ? null : selected,
              onSelected: controller.setPalette,
            ),
            const AppSectionHeader(
              title: 'Modo',
              icon: Icons.contrast_rounded,
            ),
            for (final option in _modes)
              _ModeOption(
                option: option,
                selected: option.mode == mode,
                onTap: () => controller.setMode(option.mode),
              ),
          ],
        );
      }),
    );
  }
}

class _Mode {
  final ThemeModePreference mode;
  final String title;
  final String subtitle;
  final IconData icon;

  const _Mode(this.mode, this.title, this.subtitle, this.icon);
}

const _modes = [
  _Mode(ThemeModePreference.light, 'Tema claro', 'Fondo claro',
      Icons.light_mode_rounded),
  _Mode(
      ThemeModePreference.dark,
      'Tema oscuro',
      'Fondo oscuro, descansa la '
          'vista de noche',
      Icons.dark_mode_rounded),
  _Mode(ThemeModePreference.system, 'Tema del sistema',
      'Sigue la configuración de tu teléfono', Icons.phone_iphone_rounded),
  _Mode(
      ThemeModePreference.highContrast,
      'Alto contraste',
      'Fondo negro y colores intensos, para leer mejor',
      Icons.contrast_rounded),
];

/// "Usar el del negocio" con la muestra del color del negocio.
class _BusinessPaletteOption extends StatelessWidget {
  final AppPalette business;
  final bool selected;
  final VoidCallback onTap;

  const _BusinessPaletteOption({
    required this.business,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      key: const Key('palette-business'),
      margin: EdgeInsets.zero,
      depth: selected ? 2 : 1,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      onTap: onTap,
      semanticLabel: 'Usar el del negocio',
      child: Row(
        children: [
          PaletteDot(palette: business, size: 40),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Usar el del negocio',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                Text(business.label,
                    style: TextStyle(color: scheme.onSurfaceVariant)),
              ],
            ),
          ),
          Icon(
            selected
                ? Icons.radio_button_checked_rounded
                : Icons.radio_button_off_rounded,
            color: selected ? scheme.primary : scheme.outline,
          ),
        ],
      ),
    );
  }
}

class _ModeOption extends StatelessWidget {
  final _Mode option;
  final bool selected;
  final VoidCallback onTap;

  const _ModeOption({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = context.tokens;
    return AppCard(
      key: Key('theme-mode-${option.mode.id}'),
      depth: selected ? 2 : 1,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: selected ? tokens.primaryGradient : null,
              color: selected ? null : scheme.surfaceContainerHighest,
            ),
            child: Icon(option.icon,
                color: selected ? tokens.onGradient : scheme.onSurfaceVariant),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(option.title,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(option.subtitle,
                    style: TextStyle(color: scheme.onSurfaceVariant)),
              ],
            ),
          ),
          if (selected) Icon(Icons.check_circle_rounded, color: scheme.primary),
        ],
      ),
    );
  }
}

/// Vista previa en vivo: una mini tarjeta de cita y los botones, pintados con
/// el tema actual (cambia al tocar una muestra o un modo).
class _LivePreview extends StatelessWidget {
  const _LivePreview();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = context.tokens;
    final start = DateTime(2030, 1, 1, 10);
    final end = DateTime(2030, 1, 1, 11, 5);
    return Column(
      children: [
        AppCard(
          depth: 3,
          gradient: tokens.primaryGradient,
          child: DefaultTextStyle.merge(
            style: TextStyle(color: tokens.onGradient),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(formatTimeRange(start, end),
                          style: theme.textTheme.labelLarge?.tabular
                              .copyWith(color: tokens.onGradient)),
                      const SizedBox(height: 4),
                      Text('Paula Gómez',
                          style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: tokens.onGradient)),
                      const SizedBox(height: 8),
                      StatusChip.appointment(AppointmentStatus.CONFIRMED,
                          dense: true),
                    ],
                  ),
                ),
                const AppAvatar(name: 'Laura Ruiz', radius: 20),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: AppGradientButton(
                  label: 'Principal',
                  icon: Icons.add_rounded,
                  onPressed: () {},
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  child: const Text('Secundario'),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Text(
            'Así se verán la agenda, los botones y el menú.',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}
