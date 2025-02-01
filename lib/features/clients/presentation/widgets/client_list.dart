import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/features/clients/presentation/controller/clients_controller.dart';
import 'package:login_signup/features/clients/presentation/widgets/client_list_item.dart';

class ClientList extends GetView<ClientsController> {
  const ClientList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.clients.isEmpty) {
          return const Center(
            child: Text('No hay clientes registrados'),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          itemCount: controller.clients.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final client = controller.clients[index];
            return ClientListItem(client: client);
          },
        );
      }),
    );
  }
}
