// import 'package:flutter/material.dart';

// class ClientsScreen extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SafeArea(
//         child: Column(
//           children: [
//             // Header card
//             Card(
//               child: Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text('Clientes',
//                             style: Theme.of(context).textTheme.headlineMedium),
//                         Text('Total de clientes',
//                             style: TextStyle(color: Colors.green)),
//                       ],
//                     ),
//                     Row(
//                       children: [
//                         Text('878',
//                             style: Theme.of(context).textTheme.headlineMedium),
//                         IconButton(
//                           icon: Icon(Icons.sync, color: Colors.blue),
//                           onPressed: () {},
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ),

//             // Search bar
//             Padding(
//               padding: const EdgeInsets.all(8.0),
//               child: TextField(
//                 decoration: InputDecoration(
//                   hintText: 'Buscar cliente',
//                   prefixIcon: Icon(Icons.search),
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(30),
//                     borderSide: BorderSide.none,
//                   ),
//                   filled: true,
//                   fillColor: Colors.grey[200],
//                 ),
//               ),
//             ),

//             // Clients list
//             Expanded(
//               child: ListView.builder(
//                 itemBuilder: (context, index) => ListTile(
//                   leading: CircleAvatar(
//                     backgroundColor: Colors.blue,
//                     child: Text('ZU'),
//                   ),
//                   title: Text('ZULY'),
//                   subtitle: Text('Teléfono: 3134994402'),
//                   trailing: Icon(Icons.chevron_right),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () {},
//         child: Icon(Icons.add),
//         backgroundColor: Colors.blue,
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:get/get_state_manager/src/simple/get_view.dart';
import 'package:login_signup/features/clients/presentation/controller/clients_controller.dart';

class ClientsScreen extends GetView<ClientsController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            _buildClientsList(),
          ],
        ),
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Clientes', style: Get.textTheme.headlineMedium),
                Text('Total de clientes',
                    style: TextStyle(color: Colors.green)),
              ],
            ),
            Row(
              children: [
                Obx(() => Text('${controller.clients.length}',
                    style: Get.textTheme.headlineMedium)),
                IconButton(
                  icon: Icon(Icons.sync, color: Colors.blue),
                  onPressed: controller.loadClients,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        onChanged: (value) => controller.searchQuery.value = value,
        decoration: InputDecoration(
          hintText: 'Buscar cliente',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey[200],
        ),
      ),
    );
  }

  Widget _buildClientsList() {
    return Expanded(
      child: Obx(() {
        if (controller.isLoading.value) {
          return Center(child: CircularProgressIndicator());
        }
        return ListView.builder(
          itemCount: controller.clients.length,
          itemBuilder: (context, index) {
            final client = controller.clients[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue,
                child: Text(client.name[0].toUpperCase()),
              ),
              title: Text('${client.name} ${client.lastname}'),
              subtitle: Text('Teléfono: ${client.phone}'),
              trailing: Icon(Icons.chevron_right),
              onTap: () => Get.toNamed('/clients/${client.id}'),
            );
          },
        );
      }),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton(
      onPressed: () => _showOptionsDialog(),
      child: Icon(Icons.add),
      backgroundColor: Colors.blue,
    );
  }

  void _showOptionsDialog() {
    Get.dialog(
      AlertDialog(
        title: Text('Agregar Cliente'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.person_add),
              title: Text('Nuevo Cliente'),
              onTap: () {
                Get.back();
                Get.toNamed('/clients/new');
              },
            ),
            ListTile(
              leading: Icon(Icons.import_contacts),
              title: Text('Importar Contactos'),
              onTap: () {
                Get.back();
                controller.importContacts();
              },
            ),
          ],
        ),
      ),
    );
  }
}
