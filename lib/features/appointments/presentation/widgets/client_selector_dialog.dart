// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import '../controllers/appointments_controller.dart';

// class ClientSelectorDialog extends StatelessWidget {
//   final AppointmentsController controller;
//   final Function(Map<String, dynamic>) onClientSelected;

//   const ClientSelectorDialog({
//     Key? key,
//     required this.controller,
//     required this.onClientSelected,
//   }) : super(key: key);

//   static Future<Map<String, dynamic>?> show(
//     BuildContext context,
//     AppointmentsController controller,
//   ) async {
//     Map<String, dynamic>? selectedClient;

//     await showDialog(
//       context: context,
//       builder: (context) => ClientSelectorDialog(
//         controller: controller,
//         onClientSelected: (client) {
//           selectedClient = client;
//           Navigator.pop(context);
//         },
//       ),
//     );

//     return selectedClient;
//   }

//   @override
//   Widget build(BuildContext context) {
//     final searchController = TextEditingController();
//     final searchQuery = ''.obs;

//     return Dialog(
//       child: Container(
//         width: MediaQuery.of(context).size.width * 0.9,
//         height: MediaQuery.of(context).size.height * 0.7,
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             TextField(
//               controller: searchController,
//               decoration: InputDecoration(
//                 labelText: 'Buscar Cliente',
//                 prefixIcon: const Icon(Icons.search),
//                 border: const OutlineInputBorder(),
//                 suffixIcon: IconButton(
//                   icon: const Icon(Icons.clear),
//                   onPressed: () {
//                     searchController.clear();
//                     searchQuery.value = '';
//                   },
//                 ),
//               ),
//               onChanged: (value) => searchQuery.value = value,
//             ),
//             const SizedBox(height: 16),
//             Expanded(
//               child: Obx(() {
//                 final filteredClients = controller.clients.where((client) {
//                   final name =
//                       '${client['name']} ${client['lastname']}'.toLowerCase();
//                   return name.contains(searchQuery.value.toLowerCase());
//                 }).toList();

//                 return ListView.builder(
//                   itemCount: filteredClients.length,
//                   itemBuilder: (context, index) {
//                     final client = filteredClients[index];
//                     return ListTile(
//                       leading: CircleAvatar(
//                         child: Text(client['name'][0]),
//                       ),
//                       title: Text('${client['name']} ${client['lastname']}'),
//                       subtitle: Text(client['phone'] ?? ''),
//                       onTap: () => onClientSelected(client),
//                     );
//                   },
//                 );
//               }),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

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

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(16),
          child: ClientSelectorDialog(
            controller: controller,
            onClientSelected: (client) {
              selectedClient = client;
              Navigator.pop(context, true);
            },
          ),
        ),
      ),
    );

    // Solo retornar el cliente si se confirmó la selección
    return result == true ? selectedClient : null;
  }

  @override
  Widget build(BuildContext context) {
    final searchController = TextEditingController();
    final searchQuery = ''.obs;

    return Column(
      children: [
        // Título
        Text(
          'Seleccionar Cliente',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: 20),

        // Barra de búsqueda
        TextField(
          controller: searchController,
          decoration: InputDecoration(
            labelText: 'Buscar Cliente',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                searchController.clear();
                searchQuery.value = '';
              },
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(color: Theme.of(context).primaryColor),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
          ),
          onChanged: (value) => searchQuery.value = value,
        ),
        const SizedBox(height: 16),

        // Lista de clientes
        Expanded(
          child: Obx(() {
            final filteredClients = controller.clients.where((client) {
              final name =
                  '${client['name']} ${client['lastname']}'.toLowerCase();
              return name.contains(searchQuery.value.toLowerCase());
            }).toList();

            if (filteredClients.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No se encontraron clientes',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              itemCount: filteredClients.length,
              separatorBuilder: (context, index) => Divider(height: 1),
              itemBuilder: (context, index) {
                final client = filteredClients[index];
                final clientName = '${client['name']} ${client['lastname']}';
                final firstLetter = client['name'][0].toString().toUpperCase();
                final phone = client['phone'] ?? 'Sin teléfono';

                return Card(
                  elevation: 1,
                  margin:
                      const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    onTap: () => onClientSelected(client),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          // Avatar con iniciales
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Theme.of(context)
                                      .primaryColor
                                      .withOpacity(0.7),
                                  Theme.of(context).primaryColor,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context)
                                      .primaryColor
                                      .withOpacity(0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                firstLetter,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),

                          // Información del cliente
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  clientName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.phone,
                                      size: 14,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      phone,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                                if (client['email'] != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.email,
                                          size: 14,
                                          color: Colors.grey[600],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          client['email'],
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          // Icono de selección
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Colors.grey[400],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }),
        ),

        // Botones de acción
        Container(
          padding: const EdgeInsets.only(top: 16),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: Colors.grey[300]!),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  foregroundColor: Colors.grey[700],
                ),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(fontSize: 16),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  foregroundColor: Theme.of(context).primaryColor,
                ),
                child: const Text(
                  'Nuevo Cliente',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
