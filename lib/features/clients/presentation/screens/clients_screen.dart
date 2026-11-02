import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/widgets/app_gradient_button.dart';
import '../controllers/clients_controller.dart';
import '../widgets/add_client_dialog.dart';
import '../widgets/client_list.dart';
import '../widgets/client_search_bar.dart';

/// Clientes del negocio (Owner y Employee).
class ClientsScreen extends GetView<ClientsController> {
  const ClientsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clientes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Actualizar',
            onPressed: controller.loadClients,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: Obx(() => controller.isImporting.value
              ? const LinearProgressIndicator(
                  semanticsLabel: 'Importando contactos')
              : const SizedBox(height: 4)),
        ),
      ),
      body: const Column(
        children: [
          ClientSearchBar(),
          SizedBox(height: 4),
          Expanded(child: ClientList()),
        ],
      ),
      floatingActionButton: Obx(() => AppGradientButton.fab(
            label: 'Cliente',
            icon: Icons.person_add_alt_1_rounded,
            tooltip: 'Agregar cliente',
            onPressed: controller.isImporting.value
                ? null
                : () => AddClientDialog.show(context),
          )),
    );
  }
}
