import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/shared/widgets/app_sheet.dart';
import '../controllers/clients_controller.dart';
import 'client_import_summary.dart';

/// Opciones para agregar clientes (hoja de la guía): crear uno o importar los
/// contactos del teléfono.
abstract final class AddClientDialog {
  static Future<void> show(BuildContext context) => AppSheet.show<void>(
        context,
        title: 'Agregar clientes',
        icon: Icons.person_add_alt_1_rounded,
        builder: (sheetContext) {
          final controller = Get.find<ClientsController>();
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _AddOption(
                  icon: Icons.person_add_alt_1_rounded,
                  title: 'Nuevo cliente',
                  subtitle: 'Crear un cliente desde cero',
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    controller.openNewClient();
                  },
                ),
                const SizedBox(height: 8),
                _AddOption(
                  icon: Icons.contacts_rounded,
                  title: 'Importar contactos',
                  subtitle: 'Desde los contactos del teléfono',
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    importContacts(controller);
                  },
                ),
              ],
            ),
          );
        },
      );

  /// Importa y muestra el resumen.
  static Future<void> importContacts(ClientsController controller) async {
    final result = await controller.importContacts();
    if (result != null) await showClientImportSummary(result);
  }
}

/// Opción de la hoja: ícono en un cuadro tonal, título y explicación.
class _AddOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AddOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      shape: RoundedRectangleBorder(
        borderRadius: AppRadii.fieldRadius,
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      tileColor: scheme.surfaceContainerLow,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: scheme.primaryContainer,
          borderRadius: AppRadii.chipRadius,
        ),
        child: Icon(icon, color: scheme.onPrimaryContainer),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}
