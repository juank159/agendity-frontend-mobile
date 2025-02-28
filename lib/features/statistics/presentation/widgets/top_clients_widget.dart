// // lib/features/statistics/presentation/widgets/top_clients_widget.dart
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import '../controllers/statistics_controller.dart';

// class TopClientsWidget extends StatelessWidget {
//   const TopClientsWidget({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     final controller = Get.find<StatisticsController>();

//     return Obx(() {
//       if (controller.isLoadingTopClients.value &&
//           controller.topClients.isEmpty) {
//         return const Center(
//           child: Padding(
//             padding: EdgeInsets.all(20.0),
//             child: CircularProgressIndicator(),
//           ),
//         );
//       }

//       if (controller.errorTopClients.value.isNotEmpty &&
//           controller.topClients.isEmpty) {
//         return Center(
//           child: Padding(
//             padding: const EdgeInsets.all(20.0),
//             child: Column(
//               children: [
//                 Text(
//                   'Error: ${controller.errorTopClients.value}',
//                   style: TextStyle(color: Colors.red[700]),
//                   textAlign: TextAlign.center,
//                 ),
//                 const SizedBox(height: 10),
//                 ElevatedButton(
//                   onPressed: controller.loadTopClients,
//                   child: const Text('Reintentar'),
//                 ),
//               ],
//             ),
//           ),
//         );
//       }

//       // Si no hay datos cargados, cargarlos ahora
//       if (controller.topClients.isEmpty) {
//         // Mostrar un botón para cargar los datos
//         return Center(
//           child: Padding(
//             padding: const EdgeInsets.all(20.0),
//             child: ElevatedButton.icon(
//               onPressed: controller.loadTopClients,
//               icon: const Icon(Icons.people),
//               label: const Text('Cargar mejores clientes'),
//             ),
//           ),
//         );
//       }

//       // Mostrar las tarjetas de los mejores clientes
//       final clients = controller.topClients;

//       return Column(
//         children: [
//           // Lista de tarjetas de clientes
//           ...clients
//               .map((client) => Card(
//                     margin: const EdgeInsets.only(bottom: 12),
//                     child: Padding(
//                       padding: const EdgeInsets.all(16.0),
//                       child: Row(
//                         children: [
//                           // Avatar y ranking
//                           Stack(
//                             alignment: Alignment.bottomRight,
//                             children: [
//                               CircleAvatar(
//                                 radius: 28,
//                                 backgroundColor: Theme.of(context)
//                                     .primaryColor
//                                     .withOpacity(0.2),
//                                 child: Text(
//                                   client.clientName
//                                       .substring(0, 1)
//                                       .toUpperCase(),
//                                   style: TextStyle(
//                                     fontSize: 24,
//                                     fontWeight: FontWeight.bold,
//                                     color: Theme.of(context).primaryColor,
//                                   ),
//                                 ),
//                               ),
//                               CircleAvatar(
//                                 radius: 12,
//                                 backgroundColor: Theme.of(context).primaryColor,
//                                 child: Text(
//                                   '${clients.indexOf(client) + 1}',
//                                   style: const TextStyle(
//                                     color: Colors.white,
//                                     fontWeight: FontWeight.bold,
//                                     fontSize: 12,
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                           const SizedBox(width: 16),
//                           // Información del cliente
//                           Expanded(
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Text(
//                                   client.clientName,
//                                   style: const TextStyle(
//                                     fontWeight: FontWeight.bold,
//                                     fontSize: 16,
//                                   ),
//                                 ),
//                                 const SizedBox(height: 4),
//                                 Text(
//                                   '${client.visitCount} visitas',
//                                   style: TextStyle(
//                                     color: Colors.grey[600],
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                           // Monto gastado
//                           Column(
//                             crossAxisAlignment: CrossAxisAlignment.end,
//                             children: [
//                               Text(
//                                 controller.formatCurrency(client.totalSpent),
//                                 style: const TextStyle(
//                                   fontWeight: FontWeight.bold,
//                                   fontSize: 16,
//                                 ),
//                               ),
//                               const SizedBox(height: 4),
//                               Text(
//                                 'Total gastado',
//                                 style: TextStyle(
//                                   color: Colors.grey[600],
//                                   fontSize: 12,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ],
//                       ),
//                     ),
//                   ))
//               .toList(),

//           // Botón para ver más clientes
//           TextButton.icon(
//             onPressed: () {
//               // Navegar a una vista de detalle de clientes
//               // Get.toNamed('/statistics/clients');
//               // O cargar más clientes
//               controller.loadClientStats(limit: 20);
//             },
//             icon: const Icon(Icons.people_outline),
//             label: const Text('Ver más clientes'),
//           ),
//         ],
//       );
//     });
//   }
// }

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/statistics_controller.dart';

class TopClientsWidget extends StatelessWidget {
  const TopClientsWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<StatisticsController>();

    return Obx(() {
      if (controller.isLoadingTopClients.value &&
          controller.topClients.isEmpty) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: CircularProgressIndicator(),
          ),
        );
      }

      if (controller.errorTopClients.value.isNotEmpty &&
          controller.topClients.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Text(
                  'Error: ${controller.errorTopClients.value}',
                  style: TextStyle(color: Colors.red[700]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: controller.loadTopClients,
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        );
      }

      // Si no hay datos, mostrar mensaje amigable
      if (controller.topClients.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.people_outline, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'No hay datos de clientes para el período seleccionado',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[700]),
              ),
              const SizedBox(height: 8),
              Text(
                'Prueba seleccionando un rango de fechas más amplio',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: controller.loadTopClients,
                icon: const Icon(Icons.refresh),
                label: const Text('Actualizar'),
              ),
            ],
          ),
        );
      }

      // Mostrar las tarjetas de los mejores clientes
      final clients = controller.topClients;

      return Column(
        children: [
          // Lista de tarjetas de clientes
          ...clients
              .map((client) => Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          // Avatar y ranking
                          Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundColor: Theme.of(context)
                                    .primaryColor
                                    .withOpacity(0.2),
                                child: Text(
                                  client.clientName
                                      .substring(0, 1)
                                      .toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                              ),
                              CircleAvatar(
                                radius: 12,
                                backgroundColor: Theme.of(context).primaryColor,
                                child: Text(
                                  '${clients.indexOf(client) + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          // Información del cliente
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  client.clientName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${client.visitCount} visitas',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Monto gastado
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '\$ ${NumberFormat('#,###', 'es_CO').format(client.totalSpent)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Total gastado',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ))
              .toList(),

          // Botón para ver más clientes
          TextButton.icon(
            onPressed: () {
              // Cargar más clientes
              controller.loadClientStats(limit: 20);
            },
            icon: const Icon(Icons.people_outline),
            label: const Text('Ver más clientes'),
          ),
        ],
      );
    });
  }
}
