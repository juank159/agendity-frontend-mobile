import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/features/clients/presentation/controller/clients_controller.dart';

class ClientHeader extends GetView<ClientsController> {
  const ClientHeader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16.0),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Clientes',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Total de clientes',
                  style: TextStyle(
                    color: Colors.green[400],
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Obx(() => Text(
                      '${controller.clients.length}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    )),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.sync, color: Colors.blue[600]),
                  onPressed: controller.loadClients,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
