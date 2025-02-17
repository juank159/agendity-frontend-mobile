// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:login_signup/features/appointments/domain/entities/appointment_entity.dart';
// import '../controllers/appointments_controller.dart';

// class AppointmentDetailDialog extends StatelessWidget {
//   final AppointmentEntity appointment;
//   final AppointmentsController controller;

//   const AppointmentDetailDialog({
//     Key? key,
//     required this.appointment,
//     required this.controller,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     final timeFormatter = DateFormat('h:mm a');
//     final dateFormatter = DateFormat('dd/MM/yyyy');

//     return Dialog(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       child: Container(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Encabezado con estado
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text(
//                   appointment.status == 'completed'
//                       ? 'Completado'
//                       : 'Pendiente',
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                     color: appointment.status == 'completed'
//                         ? Colors.green
//                         : Colors.orange,
//                   ),
//                 ),
//                 IconButton(
//                   icon: const Icon(Icons.edit),
//                   onPressed: () {
//                     // TODO: Implementar edición
//                   },
//                 ),
//               ],
//             ),
//             const Divider(),

//             // Información del cliente
//             ListTile(
//               leading: CircleAvatar(
//                 child: Text(appointment.clientName[0]),
//               ),
//               title: Text(appointment.clientName),
//               subtitle: const Text('Cliente'),
//             ),

//             // Detalles del servicio
//             ListTile(
//               leading: const Icon(Icons.spa),
//               title: Text(appointment.serviceType),
//               subtitle: Text('US\$ ${appointment.totalPrice}'),
//             ),

//             // Fecha y hora
//             ListTile(
//               leading: const Icon(Icons.access_time),
//               title: Text(dateFormatter.format(appointment.startTime)),
//               subtitle: Text(
//                 '${timeFormatter.format(appointment.startTime)} - '
//                 '${timeFormatter.format(appointment.endTime)}',
//               ),
//             ),

//             // Notas
//             if (appointment.notes != null && appointment.notes!.isNotEmpty)
//               ListTile(
//                 leading: const Icon(Icons.note),
//                 title: const Text('Notas'),
//                 subtitle: Text(appointment.notes!),
//               ),

//             const SizedBox(height: 16),

//             // Botones de acción
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//               children: [
//                 ElevatedButton.icon(
//                   icon: Icon(
//                     appointment.status == 'completed'
//                         ? Icons.refresh
//                         : Icons.check_circle,
//                   ),
//                   label: Text(
//                     appointment.status == 'completed'
//                         ? 'Marcar Pendiente'
//                         : 'Completar',
//                   ),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: appointment.status == 'completed'
//                         ? Colors.orange
//                         : Colors.green,
//                   ),
//                   onPressed: () {
//                     // TODO: Implementar cambio de estado
//                     Navigator.pop(context);
//                   },
//                 ),
//                 TextButton.icon(
//                   icon: const Icon(Icons.delete),
//                   label: const Text('Eliminar'),
//                   style: TextButton.styleFrom(
//                     foregroundColor: Colors.red,
//                   ),
//                   onPressed: () {
//                     // TODO: Implementar eliminación
//                     Navigator.pop(context);
//                   },
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
