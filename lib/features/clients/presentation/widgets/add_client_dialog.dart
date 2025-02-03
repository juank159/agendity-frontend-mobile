import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/features/clients/presentation/controller/clients_controller.dart';

// add_client_dialog.dart
class AddClientDialog {
  static void show() {
    Get.dialog(
      AlertDialog(
        title: const Text('Agregar Cliente'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person_add),
              title: const Text('Nuevo Cliente'),
              onTap: () {
                Get.back();
                Get.toNamed('/clients/new');
              },
            ),
            ListTile(
              leading: const Icon(Icons.import_contacts),
              title: const Text('Importar Contactos'),
              onTap: () => _importContacts(),
            ),
          ],
        ),
      ),
    );
  }

  static void _importContacts() async {
    final controller = Get.find<ClientsController>();
    Get.back();

    Get.dialog(
      WillPopScope(
        onWillPop: () async => false,
        child: const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Importando contactos...')
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );

    try {
      await controller.importContacts();
    } catch (e) {
      Get.back();
      Get.snackbar(
        'Error',
        e.toString(),
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    }
  }
}
