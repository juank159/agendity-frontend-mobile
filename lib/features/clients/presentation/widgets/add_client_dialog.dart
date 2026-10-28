import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/clients_controller.dart';
import 'client_import_summary.dart';

/// Opciones para agregar clientes: crear uno o importar los contactos.
abstract final class AddClientDialog {
  static Future<void> show(BuildContext context) => showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (sheetContext) {
          final controller = Get.find<ClientsController>();
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.person_add_alt_1),
                  title: const Text('Nuevo cliente'),
                  subtitle: const Text('Crear un cliente desde cero'),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    controller.openNewClient();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.import_contacts),
                  title: const Text('Importar contactos'),
                  subtitle: const Text('Desde los contactos del teléfono'),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    importContacts(controller);
                  },
                ),
                const SizedBox(height: 8),
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
