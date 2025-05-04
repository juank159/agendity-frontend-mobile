import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:login_signup/shared/controller/theme_controller.dart';

class ThemeSettingsScreen extends StatelessWidget {
  const ThemeSettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = ThemeController.to;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración de tema'),
        centerTitle: true,
      ),
      body: GetX<ThemeController>(
        builder: (_) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildThemeOption(
                context,
                title: 'Tema claro',
                subtitle: 'Interfaz con fondo claro',
                icon: Icons.light_mode,
                isSelected: themeController.isCurrentTheme(ThemeType.light),
                onTap: () => themeController.setTheme(ThemeType.light),
              ),
              const SizedBox(height: 16),
              _buildThemeOption(
                context,
                title: 'Tema oscuro',
                subtitle: 'Interfaz con fondo oscuro',
                icon: Icons.dark_mode,
                isSelected: themeController.isCurrentTheme(ThemeType.dark),
                onTap: () => themeController.setTheme(ThemeType.dark),
              ),
              const SizedBox(height: 16),
              _buildThemeOption(
                context,
                title: 'Tema del sistema',
                subtitle: 'Sigue la configuración de tu dispositivo',
                icon: Icons.phone_android,
                isSelected: themeController.isCurrentTheme(ThemeType.system),
                onTap: () => themeController.setTheme(ThemeType.system),
              ),
              const SizedBox(height: 16),
              _buildThemeOption(
                context,
                title: 'Alto contraste',
                subtitle: 'Tema de alto contraste (negro y amarillo)',
                icon: Icons.contrast,
                isSelected:
                    themeController.isCurrentTheme(ThemeType.highContrast),
                onTap: () => themeController.setTheme(ThemeType.highContrast),
              ),
              const SizedBox(height: 24),

              // Preview del tema actual
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).shadowColor.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vista previa del tema',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Este es un ejemplo del tema seleccionado. Puedes ver cómo se ven los diferentes elementos de la interfaz.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: () {},
                          child: const Text('Botón Principal'),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton(
                          onPressed: () {},
                          child: const Text('Botón Secundario'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Icon(Icons.star,
                            color: Theme.of(context).colorScheme.primary),
                        Icon(Icons.favorite,
                            color: Theme.of(context).colorScheme.secondary),
                        Icon(Icons.settings,
                            color: Theme.of(context).iconTheme.color),
                        Icon(Icons.warning,
                            color: Theme.of(context).colorScheme.error),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isSelected
          ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
          : Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.background,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: isSelected
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).iconTheme.color,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
