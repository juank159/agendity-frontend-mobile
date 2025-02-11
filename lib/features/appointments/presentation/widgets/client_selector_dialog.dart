import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/appointments_controller.dart';

class ClientSelectorDialog extends StatelessWidget {
  final AppointmentsController controller;
  final Function(Map<String, dynamic>) onClientSelected;

  const ClientSelectorDialog({
    Key? key,
    required this.controller,
    required this.onClientSelected,
  }) : super(key: key);

  static Future<Map<String, dynamic>?> show(
    BuildContext context,
    AppointmentsController controller,
  ) async {
    Map<String, dynamic>? selectedClient;

    await showDialog(
      context: context,
      builder: (context) => ClientSelectorDialog(
        controller: controller,
        onClientSelected: (client) {
          selectedClient = client;
          Navigator.pop(context);
        },
      ),
    );

    return selectedClient;
  }

  @override
  Widget build(BuildContext context) {
    final searchController = TextEditingController();
    final searchQuery = ''.obs;

    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: 'Buscar Cliente',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    searchController.clear();
                    searchQuery.value = '';
                  },
                ),
              ),
              onChanged: (value) => searchQuery.value = value,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Obx(() {
                final filteredClients = controller.clients.where((client) {
                  final name =
                      '${client['name']} ${client['lastname']}'.toLowerCase();
                  return name.contains(searchQuery.value.toLowerCase());
                }).toList();

                return ListView.builder(
                  itemCount: filteredClients.length,
                  itemBuilder: (context, index) {
                    final client = filteredClients[index];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(client['name'][0]),
                      ),
                      title: Text('${client['name']} ${client['lastname']}'),
                      subtitle: Text(client['phone'] ?? ''),
                      onTap: () => onClientSelected(client),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
