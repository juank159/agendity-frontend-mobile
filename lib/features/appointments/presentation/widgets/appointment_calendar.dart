// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:intl/intl.dart';
// import 'package:login_signup/features/appointments/domain/entities/appointment_entity.dart';
// import 'package:syncfusion_flutter_calendar/calendar.dart';
// import '../controllers/appointments_controller.dart';

// class AppointmentCalendar extends StatelessWidget {
//   final AppointmentsController controller;

//   const AppointmentCalendar({
//     Key? key,
//     required this.controller,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return GetBuilder<AppointmentsController>(
//       id: 'calendar-view',
//       builder: (controller) {
//         print(
//             'Reconstruyendo calendario con ${controller.appointments.length} citas');

//         return Column(
//           children: [
//             Expanded(
//               child: SfCalendar(
//                 key: ValueKey(
//                     'calendar-${controller.currentView.value}-${controller.appointments.length}-${DateTime.now().millisecondsSinceEpoch}'),
//                 view: controller.currentView.value,
//                 dataSource: controller.getCalendarDataSource(),
//                 onViewChanged: (ViewChangedDetails details) {
//                   Future.microtask(() => controller.onViewChanged(details));
//                 },
//                 initialDisplayDate: controller.selectedDate.value,
//                 headerHeight: 50,
//                 viewHeaderHeight: 60,
//                 allowViewNavigation: true,
//                 allowDragAndDrop: false,
//                 showNavigationArrow: true,
//                 showDatePickerButton: true,
//                 backgroundColor: Colors.white,
//                 todayHighlightColor: Theme.of(context).primaryColor,
//                 cellBorderColor: Colors.grey[300],
//                 firstDayOfWeek: 1,
//                 showCurrentTimeIndicator: true,
//                 onTap: (CalendarTapDetails details) {
//                   if (details.targetElement == CalendarElement.calendarCell) {
//                     final selectedDate = details.date;
//                     if (selectedDate != null) {
//                       if (controller.currentView.value == CalendarView.month) {
//                         // Al tocar un día en la vista mensual, ir a la vista diaria de ese día
//                         controller.changeView(CalendarView.day,
//                             targetDate: selectedDate);
//                       } else if (controller.currentView.value ==
//                               CalendarView.week ||
//                           controller.currentView.value ==
//                               CalendarView.workWeek) {
//                         // Al tocar un día en la vista semanal, ir a la vista diaria de ese día
//                         controller.changeView(CalendarView.day,
//                             targetDate: selectedDate);
//                       }
//                     }
//                   }
//                 },
//                 headerStyle: CalendarHeaderStyle(
//                   textAlign: TextAlign.center,
//                   textStyle: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.grey[800],
//                   ),
//                 ),
//                 timeSlotViewSettings: TimeSlotViewSettings(
//                   startHour: 6,
//                   endHour: 24,
//                   timeFormat: 'h:mm a',
//                   timeInterval: const Duration(minutes: 30),
//                   timeIntervalHeight: 70,
//                   timeTextStyle: TextStyle(
//                     fontWeight: FontWeight.w400,
//                     fontSize: 12,
//                     color: Colors.grey[700],
//                     letterSpacing: -0.2,
//                   ),
//                   timeRulerSize: 70,
//                   dateFormat: 'd',
//                   dayFormat: 'EEE',
//                 ),
//                 monthViewSettings: MonthViewSettings(
//                   dayFormat: 'EEE',
//                   showAgenda: false,
//                   navigationDirection: MonthNavigationDirection.horizontal,
//                   appointmentDisplayMode: MonthAppointmentDisplayMode.indicator,
//                   monthCellStyle: MonthCellStyle(
//                     textStyle: TextStyle(
//                       fontSize: 12,
//                       fontWeight: FontWeight.normal,
//                       color: Colors.grey[800],
//                     ),
//                     trailingDatesTextStyle: TextStyle(
//                       fontSize: 12,
//                       color: Colors.grey[400],
//                     ),
//                     leadingDatesTextStyle: TextStyle(
//                       fontSize: 12,
//                       color: Colors.grey[400],
//                     ),
//                   ),
//                 ),
//                 viewHeaderStyle: ViewHeaderStyle(
//                   backgroundColor: Colors.grey[100],
//                   dateTextStyle: TextStyle(
//                     fontSize: 14,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.grey[800],
//                   ),
//                   dayTextStyle: TextStyle(
//                     fontSize: 12,
//                     fontWeight: FontWeight.w600,
//                     color: Colors.grey[700],
//                   ),
//                 ),
//                 selectionDecoration: BoxDecoration(
//                   border: Border.all(
//                     color: Theme.of(context).primaryColor.withOpacity(0.5),
//                     width: 2,
//                   ),
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 dragAndDropSettings: DragAndDropSettings(
//                   indicatorTimeFormat: 'h:mm a',
//                   showTimeIndicator: true,
//                   timeIndicatorStyle: TextStyle(
//                     color: Theme.of(context).primaryColor,
//                     fontSize: 12,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 appointmentBuilder: _buildAppointment,
//               ),
//             ),
//             if (controller.isLoading.value)
//               Container(
//                 color: Colors.black12,
//                 child: const Center(
//                   child: CircularProgressIndicator(),
//                 ),
//               ),
//           ],
//         );
//       },
//     );
//   }

//   // Widget _buildAppointment(
//   //     BuildContext context, CalendarAppointmentDetails details) {
//   //   final appointment = details.appointments.first;
//   //   final String appointmentId = appointment.id?.toString() ?? '';

//   //   // Verificar si es una subcita (contiene "_")
//   //   final bool isSubAppointment = appointmentId.contains('_');

//   //   // Obtener el ID de la cita principal y el índice de la subcita
//   //   String mainAppointmentId = appointmentId;
//   //   int subAppointmentIndex = -1;
//   //   int totalSubAppointments = 1;

//   //   if (isSubAppointment) {
//   //     final parts = appointmentId.split('_');
//   //     if (parts.length > 1) {
//   //       mainAppointmentId = parts[0];
//   //       subAppointmentIndex = int.tryParse(parts[1]) ?? -1;
//   //     }

//   //     // Contar cuántas subcitas hay para esta cita principal
//   //     totalSubAppointments = controller.appointments
//   //             .where((app) => app.id == mainAppointmentId)
//   //             .firstOrNull
//   //             ?.serviceTypes
//   //             .length ??
//   //         1;
//   //   }

//   //   // Buscar la cita principal
//   //   final appointmentEntity = controller.appointments
//   //       .firstWhereOrNull((app) => app.id == mainAppointmentId);

//   //   if (appointmentEntity == null) return const SizedBox.shrink();

//   //   // Vista Mensual
//   //   if (controller.currentView.value == CalendarView.month) {
//   //     return GestureDetector(
//   //       onTap: () => _showAppointmentDetails(context, appointmentEntity),
//   //       child: Container(
//   //         margin: const EdgeInsets.symmetric(horizontal: 1),
//   //         decoration: BoxDecoration(
//   //           color: appointment.color,
//   //           borderRadius: BorderRadius.circular(2),
//   //         ),
//   //         child: Stack(
//   //           children: [
//   //             Center(
//   //               child: Column(
//   //                 mainAxisAlignment: MainAxisAlignment.center,
//   //                 children: [
//   //                   Text(
//   //                     isSubAppointment
//   //                         ? appointmentEntity.serviceTypes.join(', ')
//   //                         : appointment.subject.split('\n').isNotEmpty
//   //                             ? appointment.subject.split('\n')[0]
//   //                             : '',
//   //                     style: const TextStyle(
//   //                       color: Colors.white,
//   //                       fontSize: 10,
//   //                     ),
//   //                     maxLines: 1,
//   //                     overflow: TextOverflow.ellipsis,
//   //                   ),
//   //                   Text(
//   //                     DateFormat('h:mm a')
//   //                         .format(appointment.startTime.toLocal()),
//   //                     style: const TextStyle(
//   //                       color: Colors.white,
//   //                       fontSize: 9,
//   //                     ),
//   //                     maxLines: 1,
//   //                     overflow: TextOverflow.ellipsis,
//   //                   ),
//   //                 ],
//   //               ),
//   //             ),
//   //             Positioned(
//   //               top: 0,
//   //               right: 0,
//   //               child: Container(
//   //                 width: 6,
//   //                 height: 6,
//   //                 decoration: BoxDecoration(
//   //                   color: appointmentEntity.getStatusColor(),
//   //                   shape: BoxShape.circle,
//   //                 ),
//   //               ),
//   //             ),
//   //           ],
//   //         ),
//   //       ),
//   //     );
//   //   }

//   //   // Vista diaria/semanal con estilo unificado para citas múltiples
//   //   String serviceText = '';
//   //   String clientName = '';

//   //   if (isSubAppointment) {
//   //     // Para subcitas, extraer el servicio específico
//   //     if (subAppointmentIndex >= 0 &&
//   //         subAppointmentIndex < appointmentEntity.serviceTypes.length) {
//   //       serviceText = appointmentEntity.serviceTypes[subAppointmentIndex];
//   //     }
//   //     clientName = appointmentEntity.clientName;
//   //   } else {
//   //     // Para citas normales, usar el subject
//   //     final parts = appointment.subject.split('\n');
//   //     clientName = parts.isNotEmpty ? parts[0] : '';
//   //     serviceText = parts.length > 1 ? parts[1] : '';
//   //   }

//   //   return GestureDetector(
//   //     onTap: () => _showAppointmentDetails(context, appointmentEntity),
//   //     child: Container(
//   //       constraints: BoxConstraints(
//   //         minHeight: 30,
//   //       ),
//   //       decoration: BoxDecoration(
//   //         color: appointment.color,
//   //         borderRadius: _getBorderRadiusForSubAppointment(
//   //             subAppointmentIndex, totalSubAppointments),
//   //         boxShadow: [
//   //           BoxShadow(
//   //             color: Colors.black.withOpacity(0.15),
//   //             blurRadius: 4,
//   //             offset: const Offset(0, 2),
//   //           ),
//   //         ],
//   //         // Borde superior e inferior para mostrar continuidad entre subcitas
//   //         border: _getBorderForSubAppointment(
//   //             subAppointmentIndex, totalSubAppointments, appointment.color),
//   //       ),
//   //       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//   //       child: Row(
//   //         children: [
//   //           // Indicador numérico para subcitas (1/3, 2/3, etc.)
//   //           if (isSubAppointment && totalSubAppointments > 1)
//   //             Container(
//   //               padding: EdgeInsets.all(4),
//   //               margin: EdgeInsets.only(right: 8),
//   //               decoration: BoxDecoration(
//   //                 color: Colors.white.withOpacity(0.3),
//   //                 borderRadius: BorderRadius.circular(4),
//   //               ),
//   //               child: Text(
//   //                 "${subAppointmentIndex + 1}/$totalSubAppointments",
//   //                 style: TextStyle(
//   //                   color: Colors.white,
//   //                   fontSize: 10,
//   //                   fontWeight: FontWeight.bold,
//   //                 ),
//   //               ),
//   //             ),
//   //           Expanded(
//   //             child: Column(
//   //               mainAxisAlignment: MainAxisAlignment.center,
//   //               crossAxisAlignment: CrossAxisAlignment.start,
//   //               mainAxisSize: MainAxisSize.min,
//   //               children: [
//   //                 Text(
//   //                   serviceText,
//   //                   style: const TextStyle(
//   //                     color: Colors.white,
//   //                     fontSize: 12,
//   //                     fontWeight: FontWeight.bold,
//   //                   ),
//   //                   maxLines: 1,
//   //                   overflow: TextOverflow.ellipsis,
//   //                 ),
//   //                 const SizedBox(height: 1),
//   //                 Text(
//   //                   clientName,
//   //                   style: TextStyle(
//   //                     color: Colors.white.withOpacity(0.9),
//   //                     fontSize: 11,
//   //                   ),
//   //                   maxLines: 1,
//   //                   overflow: TextOverflow.ellipsis,
//   //                 ),
//   //               ],
//   //             ),
//   //           ),
//   //           // Solo mostrar indicador de estado en la primera subcita
//   //           if (!isSubAppointment || subAppointmentIndex == 0)
//   //             Container(
//   //               width: 10,
//   //               height: 10,
//   //               margin: const EdgeInsets.only(left: 8),
//   //               decoration: BoxDecoration(
//   //                 color: appointmentEntity.getStatusColor(),
//   //                 shape: BoxShape.circle,
//   //                 border: Border.all(
//   //                   color: Colors.white,
//   //                   width: 1.5,
//   //                 ),
//   //                 boxShadow: [
//   //                   BoxShadow(
//   //                     color:
//   //                         appointmentEntity.getStatusColor().withOpacity(0.4),
//   //                     blurRadius: 6,
//   //                     spreadRadius: 2,
//   //                   ),
//   //                 ],
//   //               ),
//   //             ),
//   //         ],
//   //       ),
//   //     ),
//   //   );
//   // }

//   Widget _buildAppointment(
//       BuildContext context, CalendarAppointmentDetails details) {
//     final appointment = details.appointments.first;
//     final String appointmentId = appointment.id?.toString() ?? '';

//     // Verificar si es una subcita (contiene "_")
//     final bool isSubAppointment = appointmentId.contains('_');

//     // Obtener el ID de la cita principal y el índice de la subcita
//     String mainAppointmentId = appointmentId;
//     int subAppointmentIndex = -1;
//     int totalSubAppointments = 1;

//     if (isSubAppointment) {
//       final parts = appointmentId.split('_');
//       if (parts.length > 1) {
//         mainAppointmentId = parts[0];
//         subAppointmentIndex = int.tryParse(parts[1]) ?? -1;
//       }

//       // Contar cuántas subcitas hay para esta cita principal
//       totalSubAppointments = controller.appointments
//               .where((app) => app.id == mainAppointmentId)
//               .firstOrNull
//               ?.serviceTypes
//               .length ??
//           1;
//     }

//     // Buscar la cita principal
//     final appointmentEntity = controller.appointments
//         .firstWhereOrNull((app) => app.id == mainAppointmentId);

//     if (appointmentEntity == null) return const SizedBox.shrink();

//     // Vista Mensual
//     if (controller.currentView.value == CalendarView.month) {
//       return GestureDetector(
//         onTap: () => _showAppointmentDetails(context, appointmentEntity),
//         child: Container(
//           margin: const EdgeInsets.symmetric(horizontal: 1),
//           decoration: BoxDecoration(
//             color: appointment.color,
//             borderRadius: BorderRadius.circular(4),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.1),
//                 blurRadius: 2,
//                 offset: const Offset(0, 1),
//               ),
//             ],
//           ),
//           child: Stack(
//             children: [
//               Center(
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Text(
//                       isSubAppointment
//                           ? appointmentEntity.serviceTypes.join(', ')
//                           : appointment.subject.split('\n').isNotEmpty
//                               ? appointment.subject.split('\n')[0]
//                               : '',
//                       style: const TextStyle(
//                         color: Colors.white,
//                         fontSize: 10,
//                         fontWeight: FontWeight.w500,
//                       ),
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                     Text(
//                       DateFormat('h:mm a')
//                           .format(appointment.startTime.toLocal()),
//                       style: const TextStyle(
//                         color: Colors.white,
//                         fontSize: 9,
//                       ),
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                   ],
//                 ),
//               ),
//               // Indicador de estado unificado para la cita
//               Positioned(
//                 top: 0,
//                 right: 0,
//                 child: Container(
//                   width: 6,
//                   height: 6,
//                   decoration: BoxDecoration(
//                     color: appointmentEntity.getStatusColor(),
//                     shape: BoxShape.circle,
//                     border: Border.all(
//                       color: Colors.white,
//                       width: 0.5,
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       );
//     }

//     // Vista diaria/semanal con enfoque en citas múltiples
//     String serviceText = '';
//     String clientName = '';

//     if (isSubAppointment) {
//       // Para subcitas, extraer el servicio específico
//       if (subAppointmentIndex >= 0 &&
//           subAppointmentIndex < appointmentEntity.serviceTypes.length) {
//         serviceText = appointmentEntity.serviceTypes[subAppointmentIndex];
//       }
//       clientName = appointmentEntity.clientName;
//     } else {
//       // Para citas normales, usar el subject
//       final parts = appointment.subject.split('\n');
//       clientName = parts.isNotEmpty ? parts[0] : '';
//       serviceText = parts.length > 1 ? parts[1] : '';
//     }

//     // Calcular el color base y los bordes según la posición de la subcita
//     final baseColor = appointment.color;
//     final bool isFirstSubAppointment = subAppointmentIndex == 0;
//     final bool isLastSubAppointment =
//         subAppointmentIndex == totalSubAppointments - 1;

//     // Nueva aproximación: Diseño unificado con gradiente para múltiples servicios
//     return GestureDetector(
//       onTap: () => _showAppointmentDetails(context, appointmentEntity),
//       child: Container(
//         constraints: const BoxConstraints(
//           minHeight: 32,
//         ),
//         margin: EdgeInsets.symmetric(
//           horizontal: 3,
//           vertical: isSubAppointment ? 0.25 : 3,
//         ),
//         decoration: BoxDecoration(
//           // Gradiente suave para subcitas, color sólido para citas simples
//           gradient: isSubAppointment
//               ? LinearGradient(
//                   begin: Alignment.topCenter,
//                   end: Alignment.bottomCenter,
//                   colors: [
//                     baseColor,
//                     Color.lerp(baseColor,
//                         isLastSubAppointment ? Colors.white : baseColor, 0.1)!,
//                   ],
//                 )
//               : null,
//           color: isSubAppointment ? null : baseColor,
//           borderRadius: isSubAppointment
//               ? _getSubAppointmentBorderRadius(
//                   subAppointmentIndex, totalSubAppointments)
//               : BorderRadius.circular(8),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(isSubAppointment ? 0.08 : 0.15),
//               blurRadius: isSubAppointment ? 2 : 4,
//               offset: Offset(0, isSubAppointment ? 1 : 2),
//             ),
//           ],
//         ),
//         child: Stack(
//           children: [
//             // Contenedor principal con información de la cita
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//               child: Row(
//                 children: [
//                   // Columna principal con información de servicio y cliente
//                   Expanded(
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         Text(
//                           serviceText,
//                           style: TextStyle(
//                             color: Colors.white,
//                             fontSize: 12,
//                             fontWeight: FontWeight.bold,
//                             letterSpacing: 0.1,
//                           ),
//                           maxLines: 1,
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                         const SizedBox(height: 2),
//                         Text(
//                           clientName,
//                           style: TextStyle(
//                             color: Colors.white.withOpacity(0.85),
//                             fontSize: 11,
//                           ),
//                           maxLines: 1,
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                       ],
//                     ),
//                   ),

//                   // Para citas múltiples, mostrar indicador de servicio
//                   if (totalSubAppointments > 1)
//                     Container(
//                       padding: const EdgeInsets.symmetric(
//                           horizontal: 6, vertical: 2),
//                       margin: const EdgeInsets.only(left: 4),
//                       decoration: BoxDecoration(
//                         color: Colors.white.withOpacity(0.2),
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       child: Text(
//                         isSubAppointment
//                             ? "${subAppointmentIndex + 1}/$totalSubAppointments"
//                             : "1/$totalSubAppointments",
//                         style: const TextStyle(
//                           color: Colors.white,
//                           fontSize: 9,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ),
//                 ],
//               ),
//             ),

//             // Indicador de estado unificado (sólo en la primera subcita o cita única)
//             if (isFirstSubAppointment || !isSubAppointment)
//               Positioned(
//                 top: 0,
//                 right: 0,
//                 child: Container(
//                   width: 12,
//                   height: 12,
//                   margin: const EdgeInsets.all(6),
//                   decoration: BoxDecoration(
//                     color: appointmentEntity.getStatusColor(),
//                     shape: BoxShape.circle,
//                     border: Border.all(
//                       color: Colors.white,
//                       width: 1.5,
//                     ),
//                     boxShadow: [
//                       BoxShadow(
//                         color:
//                             appointmentEntity.getStatusColor().withOpacity(0.4),
//                         blurRadius: 3,
//                         spreadRadius: 1,
//                       ),
//                     ],
//                   ),
//                 ),
//               ),

//             // Línea decorativa lateral para subcitas (da sensación de unidad)
//             if (isSubAppointment)
//               Positioned(
//                 top: 0,
//                 bottom: 0,
//                 left: 0,
//                 child: Container(
//                   width: 3,
//                   decoration: BoxDecoration(
//                     color: appointmentEntity.getStatusColor(),
//                     borderRadius: BorderRadius.only(
//                       topLeft: isFirstSubAppointment
//                           ? const Radius.circular(8)
//                           : Radius.zero,
//                       bottomLeft: isLastSubAppointment
//                           ? const Radius.circular(8)
//                           : Radius.zero,
//                     ),
//                   ),
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }

//   BorderRadius _getSubAppointmentBorderRadius(int index, int total) {
//     if (total <= 1 || index < 0) {
//       return BorderRadius.circular(8);
//     }

//     if (index == 0) {
//       // Primera subcita: bordes redondeados arriba
//       return const BorderRadius.only(
//         topLeft: Radius.circular(8),
//         topRight: Radius.circular(8),
//         bottomLeft: Radius.circular(1),
//         bottomRight: Radius.circular(1),
//       );
//     } else if (index == total - 1) {
//       // Última subcita: bordes redondeados abajo
//       return const BorderRadius.only(
//         topLeft: Radius.circular(1),
//         topRight: Radius.circular(1),
//         bottomLeft: Radius.circular(8),
//         bottomRight: Radius.circular(8),
//       );
//     } else {
//       // Subcitas intermedias: bordes mínimos
//       return BorderRadius.circular(1);
//     }
//   }

// // Función para obtener bordes redondeados solo en los extremos de las subcitas
//   BorderRadius _getBorderRadiusForSubAppointment(int index, int total) {
//     if (total <= 1 || index < 0) {
//       // Cita simple o desconocida: bordes redondeados en todos lados
//       return BorderRadius.circular(8);
//     }

//     if (index == 0) {
//       // Primera subcita: bordes redondeados arriba
//       return BorderRadius.vertical(
//         top: Radius.circular(8),
//         bottom: Radius.circular(2),
//       );
//     } else if (index == total - 1) {
//       // Última subcita: bordes redondeados abajo
//       return BorderRadius.vertical(
//         top: Radius.circular(2),
//         bottom: Radius.circular(8),
//       );
//     } else {
//       // Subcitas intermedias: bordes mínimos
//       return BorderRadius.circular(2);
//     }
//   }

// // Función para obtener bordes que muestren continuidad
//   Border? _getBorderForSubAppointment(int index, int total, Color color) {
//     if (total <= 1 || index < 0) {
//       // Cita simple o desconocida: sin bordes especiales
//       return null;
//     }

//     Color borderColor = color.withOpacity(0.7);

//     if (index == 0) {
//       // Primera subcita: borde inferior
//       return Border(
//         bottom: BorderSide(
//           color: borderColor,
//           width: 1.0,
//           style: BorderStyle.solid,
//         ),
//       );
//     } else if (index == total - 1) {
//       // Última subcita: borde superior
//       return Border(
//         top: BorderSide(
//           color: borderColor,
//           width: 1.0,
//           style: BorderStyle.solid,
//         ),
//       );
//     } else {
//       // Subcitas intermedias: bordes arriba y abajo
//       return Border(
//         top: BorderSide(
//           color: borderColor,
//           width: 1.0,
//           style: BorderStyle.solid,
//         ),
//         bottom: BorderSide(
//           color: borderColor,
//           width: 1.0,
//           style: BorderStyle.solid,
//         ),
//       );
//     }
//   }

// // Función auxiliar para obtener el color del servicio
//   Color _getServiceColor(AppointmentEntity entity, int index) {
//     if (entity.colors != null && index < entity.colors!.length) {
//       try {
//         final colorStr = entity.colors![index].replaceAll('#', '');
//         return Color(int.parse('FF$colorStr', radix: 16));
//       } catch (e) {
//         print('Error al convertir color: $e');
//       }
//     }
//     return entity.getPrimaryColor();
//   }

//   // void _showAppointmentDetails(
//   //     BuildContext context, AppointmentEntity appointment) {
//   //   showDialog(
//   //     context: context,
//   //     builder: (context) => Dialog(
//   //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//   //       child: Container(
//   //         padding: const EdgeInsets.all(16),
//   //         child: Column(
//   //           mainAxisSize: MainAxisSize.min,
//   //           crossAxisAlignment: CrossAxisAlignment.start,
//   //           children: [
//   //             Row(
//   //               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//   //               children: [
//   //                 Text(
//   //                   appointment.getStatusText(),
//   //                   style: TextStyle(
//   //                     fontSize: 18,
//   //                     fontWeight: FontWeight.bold,
//   //                     color: appointment.getStatusColor(),
//   //                   ),
//   //                 ),
//   //                 IconButton(
//   //                   icon: const Icon(Icons.close),
//   //                   onPressed: () => Navigator.pop(context),
//   //                 ),
//   //               ],
//   //             ),
//   //             const Divider(),
//   //             ListTile(
//   //               leading: const Icon(Icons.access_time),
//   //               title: Text(DateFormat('dd/MM/yyyy')
//   //                   .format(appointment.startTime.toLocal())),
//   //               subtitle: Text(
//   //                 '${DateFormat('h:mm a').format(appointment.startTime.toLocal())} - '
//   //                 '${DateFormat('h:mm a').format(appointment.endTime.toLocal())}',
//   //               ),
//   //             ),
//   //             ListTile(
//   //               leading: const Icon(Icons.person),
//   //               title: const Text('Cliente'),
//   //               subtitle: Text(appointment.clientName),
//   //             ),
//   //             ListTile(
//   //               leading: const Icon(Icons.business_center),
//   //               title: const Text('Servicios'),
//   //               subtitle: Text(appointment.serviceTypes.join('\n')),
//   //             ),
//   //             if (appointment.notes?.isNotEmpty ?? false)
//   //               ListTile(
//   //                 leading: const Icon(Icons.note),
//   //                 title: const Text('Notas'),
//   //                 subtitle: Text(appointment.notes!),
//   //               ),
//   //             if (appointment.paymentStatus != null)
//   //               ListTile(
//   //                 leading: const Icon(Icons.payment),
//   //                 title: const Text('Estado de pago'),
//   //                 subtitle: Text(
//   //                   appointment.getPaymentStatusText(),
//   //                   style: TextStyle(
//   //                     color: appointment.getPaymentStatusColor(),
//   //                     fontWeight: FontWeight.bold,
//   //                   ),
//   //                 ),
//   //               ),
//   //             ListTile(
//   //               leading: const Icon(Icons.attach_money),
//   //               title: const Text('Precio total'),
//   //               subtitle: Text('\$${appointment.totalPrice}'),
//   //             ),
//   //           ],
//   //         ),
//   //       ),
//   //     ),
//   //   );
//   // }

//   void _showAppointmentDetails(BuildContext context, AppointmentEntity appointment) {
//   final totalDuration = appointment.endTime.difference(appointment.startTime);
//   final hours = totalDuration.inHours;
//   final minutes = totalDuration.inMinutes % 60;
//   final durationText = hours > 0
//       ? '$hours h ${minutes > 0 ? '$minutes min' : ''}'
//       : '$minutes min';

//   showDialog(
//     context: context,
//     builder: (context) => Dialog(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           // Encabezado con color según estado
//           Container(
//             padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
//             decoration: BoxDecoration(
//               color: appointment.getStatusColor().withOpacity(0.9),
//               borderRadius: const BorderRadius.only(
//                 topLeft: Radius.circular(16),
//                 topRight: Radius.circular(16),
//               ),
//             ),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         appointment.getStatusText(),
//                         style: const TextStyle(
//                           color: Colors.white,
//                           fontSize: 14,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                       const SizedBox(height: 2),
//                       Text(
//                         appointment.clientName,
//                         style: const TextStyle(
//                           color: Colors.white,
//                           fontSize: 18,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 IconButton(
//                   icon: const Icon(Icons.close, color: Colors.white),
//                   onPressed: () => Navigator.pop(context),
//                 ),
//               ],
//             ),
//           ),

//           // Contenido principal
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Fecha y hora
//                 Row(
//                   children: [
//                     Container(
//                       padding: const EdgeInsets.all(8),
//                       decoration: BoxDecoration(
//                         color: Colors.grey[100],
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       child: const Icon(Icons.access_time, color: Colors.grey),
//                     ),
//                     const SizedBox(width: 16),
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             DateFormat('EEEE, dd MMMM yyyy', 'es')
//                                 .format(appointment.startTime.toLocal())
//                                 .capitalize(),
//                             style: TextStyle(
//                               fontWeight: FontWeight.w500,
//                               color: Colors.grey[800],
//                             ),
//                           ),
//                           const SizedBox(height: 4),
//                           Row(
//                             children: [
//                               Text(
//                                 '${DateFormat('h:mm a').format(appointment.startTime.toLocal())} - '
//                                 '${DateFormat('h:mm a').format(appointment.endTime.toLocal())}',
//                                 style: TextStyle(
//                                   color: Colors.grey[600],
//                                 ),
//                               ),
//                               const SizedBox(width: 8),
//                               Container(
//                                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
//                                 decoration: BoxDecoration(
//                                   color: Colors.grey[200],
//                                   borderRadius: BorderRadius.circular(12),
//                                 ),
//                                 child: Text(
//                                   durationText,
//                                   style: TextStyle(
//                                     fontSize: 12,
//                                     color: Colors.grey[700],
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),

//                 const Divider(height: 32),

//                 // Servicios
//                 Row(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Container(
//                       padding: const EdgeInsets.all(8),
//                       decoration: BoxDecoration(
//                         color: Colors.grey[100],
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       child: const Icon(Icons.spa, color: Colors.grey),
//                     ),
//                     const SizedBox(width: 16),
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             'Servicios',
//                             style: TextStyle(
//                               fontWeight: FontWeight.w500,
//                               color: Colors.grey[800],
//                             ),
//                           ),
//                           const SizedBox(height: 8),
//                           ...appointment.serviceTypes.map((service) => Padding(
//                             padding: const EdgeInsets.only(bottom: 8),
//                             child: Row(
//                               children: [
//                                 Container(
//                                   width: 8,
//                                   height: 8,
//                                   decoration: BoxDecoration(
//                                     color: appointment.getPrimaryColor(),
//                                     shape: BoxShape.circle,
//                                   ),
//                                 ),
//                                 const SizedBox(width: 8),
//                                 Expanded(child: Text(service)),
//                               ],
//                             ),
//                           )).toList(),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),

//                 const Divider(height: 32),

//                 // Precio y estado de pago
//                 Row(
//                   children: [
//                     Expanded(
//                       child: Row(
//                         children: [
//                           Container(
//                             padding: const EdgeInsets.all(8),
//                             decoration: BoxDecoration(
//                               color: Colors.grey[100],
//                               borderRadius: BorderRadius.circular(8),
//                             ),
//                             child: const Icon(Icons.attach_money, color: Colors.grey),
//                           ),
//                           const SizedBox(width: 16),
//                           Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 'Precio total',
//                                 style: TextStyle(
//                                   fontWeight: FontWeight.w500,
//                                   color: Colors.grey[800],
//                                 ),
//                               ),
//                               Text(
//                                 '\$${appointment.totalPrice}',
//                                 style: const TextStyle(
//                                   fontSize: 18,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ],
//                       ),
//                     ),
//                     if (appointment.paymentStatus != null)
//                       Container(
//                         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//                         decoration: BoxDecoration(
//                           color: appointment.getPaymentStatusColor().withOpacity(0.1),
//                           borderRadius: BorderRadius.circular(20),
//                           border: Border.all(
//                             color: appointment.getPaymentStatusColor().withOpacity(0.5),
//                             width: 1,
//                           ),
//                         ),
//                         child: Text(
//                           appointment.getPaymentStatusText(),
//                           style: TextStyle(
//                             color: appointment.getPaymentStatusColor(),
//                             fontWeight: FontWeight.w600,
//                             fontSize: 12,
//                           ),
//                         ),
//                       ),
//                   ],
//                 ),

//                 // Notas (si existen)
//                 if (appointment.notes?.isNotEmpty ?? false) ...[
//                   const Divider(height: 32),
//                   Row(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Container(
//                         padding: const EdgeInsets.all(8),
//                         decoration: BoxDecoration(
//                           color: Colors.grey[100],
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                         child: const Icon(Icons.note, color: Colors.grey),
//                       ),
//                       const SizedBox(width: 16),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               'Notas',
//                               style: TextStyle(
//                                 fontWeight: FontWeight.w500,
//                                 color: Colors.grey[800],
//                               ),
//                             ),
//                             const SizedBox(height: 4),
//                             Text(
//                               appointment.notes!,
//                               style: TextStyle(
//                                 color: Colors.grey[600],
//                                 height: 1.4,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],

//                 const SizedBox(height: 24),

//                 // Botones de acción
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.end,
//                   children: [
//                     TextButton(
//                       onPressed: () => Navigator.pop(context),
//                       child: const Text('Cerrar'),
//                     ),
//                     const SizedBox(width: 8),
//                     ElevatedButton.icon(
//                       onPressed: () {
//                         // Acción para editar cita
//                         Navigator.pop(context);
//                       },
//                       icon: const Icon(Icons.edit, size: 18),
//                       label: const Text('Editar cita'),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Theme.of(context).primaryColor,
//                         foregroundColor: Colors.white,
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     ),
//   );
// }

// // Extensión para capitalizar textos (para formatos de fecha en español)
// extension StringExtension on String {
//   String capitalize() {
//     return "${this[0].toUpperCase()}${substring(1)}";
//   }
// }
// }

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:login_signup/features/appointments/domain/entities/appointment_entity.dart';
import 'package:login_signup/features/appointments/presentation/widgets/appointment_detail_dialog.dart';

import 'package:syncfusion_flutter_calendar/calendar.dart';
import '../controllers/appointments_controller.dart';

class AppointmentCalendar extends StatelessWidget {
  final AppointmentsController controller;

  const AppointmentCalendar({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AppointmentsController>(
      id: 'calendar-view',
      builder: (controller) {
        print(
            'Reconstruyendo calendario con ${controller.appointments.length} citas');

        return Column(
          children: [
            Expanded(
              child: SfCalendar(
                key: ValueKey(
                    'calendar-${controller.currentView.value}-${controller.appointments.length}-${DateTime.now().millisecondsSinceEpoch}'),
                view: controller.currentView.value,
                dataSource: controller.getCalendarDataSource(),
                onViewChanged: (ViewChangedDetails details) {
                  Future.microtask(() => controller.onViewChanged(details));
                },
                initialDisplayDate: controller.selectedDate.value,
                headerHeight: 50,
                viewHeaderHeight: 60,
                allowViewNavigation: true,
                allowDragAndDrop: false,
                showNavigationArrow: true,
                showDatePickerButton: true,
                backgroundColor: Colors.white,
                todayHighlightColor: Theme.of(context).primaryColor,
                cellBorderColor: Colors.grey[300],
                firstDayOfWeek: 1,
                showCurrentTimeIndicator: true,
                onTap: (CalendarTapDetails details) {
                  if (details.targetElement == CalendarElement.calendarCell) {
                    final selectedDate = details.date;
                    if (selectedDate != null) {
                      if (controller.currentView.value == CalendarView.month) {
                        // Al tocar un día en la vista mensual, ir a la vista diaria de ese día
                        controller.changeView(CalendarView.day,
                            targetDate: selectedDate);
                      } else if (controller.currentView.value ==
                              CalendarView.week ||
                          controller.currentView.value ==
                              CalendarView.workWeek) {
                        // Al tocar un día en la vista semanal, ir a la vista diaria de ese día
                        controller.changeView(CalendarView.day,
                            targetDate: selectedDate);
                      }
                    }
                  }
                },
                headerStyle: CalendarHeaderStyle(
                  textAlign: TextAlign.center,
                  textStyle: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                timeSlotViewSettings: TimeSlotViewSettings(
                  startHour: 6,
                  endHour: 24,
                  timeFormat: 'h:mm a',
                  timeInterval: const Duration(minutes: 30),
                  timeIntervalHeight: 70,
                  timeTextStyle: TextStyle(
                    fontWeight: FontWeight.w400,
                    fontSize: 12,
                    color: Colors.grey[700],
                    letterSpacing: -0.2,
                  ),
                  timeRulerSize: 70,
                  dateFormat: 'd',
                  dayFormat: 'EEE',
                ),
                monthViewSettings: MonthViewSettings(
                  dayFormat: 'EEE',
                  showAgenda: false,
                  navigationDirection: MonthNavigationDirection.horizontal,
                  appointmentDisplayMode: MonthAppointmentDisplayMode.indicator,
                  monthCellStyle: MonthCellStyle(
                    textStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                      color: Colors.grey[800],
                    ),
                    trailingDatesTextStyle: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[400],
                    ),
                    leadingDatesTextStyle: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[400],
                    ),
                  ),
                ),
                viewHeaderStyle: ViewHeaderStyle(
                  backgroundColor: Colors.grey[100],
                  dateTextStyle: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                  dayTextStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                selectionDecoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).primaryColor.withOpacity(0.5),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                dragAndDropSettings: DragAndDropSettings(
                  indicatorTimeFormat: 'h:mm a',
                  showTimeIndicator: true,
                  timeIndicatorStyle: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                appointmentBuilder: _buildAppointment,
              ),
            ),
            if (controller.isLoading.value)
              Container(
                color: Colors.black12,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        );
      },
    );
  }

  // Widget _buildAppointment(
  //     BuildContext context, CalendarAppointmentDetails details) {
  //   final appointment = details.appointments.first;
  //   final String appointmentId = appointment.id?.toString() ?? '';

  //   // Verificar si es una subcita (contiene "_")
  //   final bool isSubAppointment = appointmentId.contains('_');

  //   // Obtener el ID de la cita principal y el índice de la subcita
  //   String mainAppointmentId = appointmentId;
  //   int subAppointmentIndex = -1;
  //   int totalSubAppointments = 1;

  //   if (isSubAppointment) {
  //     final parts = appointmentId.split('_');
  //     if (parts.length > 1) {
  //       mainAppointmentId = parts[0];
  //       subAppointmentIndex = int.tryParse(parts[1]) ?? -1;
  //     }

  //     // Contar cuántas subcitas hay para esta cita principal
  //     totalSubAppointments = controller.appointments
  //             .where((app) => app.id == mainAppointmentId)
  //             .firstOrNull
  //             ?.serviceTypes
  //             .length ??
  //         1;
  //   }

  //   // Buscar la cita principal
  //   final appointmentEntity = controller.appointments
  //       .firstWhereOrNull((app) => app.id == mainAppointmentId);

  //   if (appointmentEntity == null) return const SizedBox.shrink();

  //   // Vista Mensual
  //   if (controller.currentView.value == CalendarView.month) {
  //     return GestureDetector(
  //       onTap: () => showAppointmentDetails(context, appointmentEntity),
  //       child: Container(
  //         margin: const EdgeInsets.symmetric(horizontal: 1),
  //         decoration: BoxDecoration(
  //           color: appointment.color,
  //           borderRadius: BorderRadius.circular(4),
  //           boxShadow: [
  //             BoxShadow(
  //               color: Colors.black.withOpacity(0.1),
  //               blurRadius: 2,
  //               offset: const Offset(0, 1),
  //             ),
  //           ],
  //         ),
  //         child: Stack(
  //           children: [
  //             Center(
  //               child: Column(
  //                 mainAxisAlignment: MainAxisAlignment.center,
  //                 children: [
  //                   Text(
  //                     isSubAppointment
  //                         ? appointmentEntity.serviceTypes.join(', ')
  //                         : appointment.subject.split('\n').isNotEmpty
  //                             ? appointment.subject.split('\n')[0]
  //                             : '',
  //                     style: const TextStyle(
  //                       color: Colors.white,
  //                       fontSize: 10,
  //                       fontWeight: FontWeight.w500,
  //                     ),
  //                     maxLines: 1,
  //                     overflow: TextOverflow.ellipsis,
  //                   ),
  //                   Text(
  //                     DateFormat('h:mm a')
  //                         .format(appointment.startTime.toLocal()),
  //                     style: const TextStyle(
  //                       color: Colors.white,
  //                       fontSize: 9,
  //                     ),
  //                     maxLines: 1,
  //                     overflow: TextOverflow.ellipsis,
  //                   ),
  //                 ],
  //               ),
  //             ),
  //             // Indicador de estado unificado para la cita
  //             Positioned(
  //               top: 0,
  //               right: 0,
  //               child: Container(
  //                 width: 6,
  //                 height: 6,
  //                 decoration: BoxDecoration(
  //                   color: appointmentEntity.getStatusColor(),
  //                   shape: BoxShape.circle,
  //                   border: Border.all(
  //                     color: Colors.white,
  //                     width: 0.5,
  //                   ),
  //                 ),
  //               ),
  //             ),
  //           ],
  //         ),
  //       ),
  //     );
  //   }

  //   // Vista diaria/semanal con enfoque en citas múltiples
  //   String serviceText = '';
  //   String clientName = '';

  //   if (isSubAppointment) {
  //     // Para subcitas, extraer el servicio específico
  //     if (subAppointmentIndex >= 0 &&
  //         subAppointmentIndex < appointmentEntity.serviceTypes.length) {
  //       serviceText = appointmentEntity.serviceTypes[subAppointmentIndex];
  //     }
  //     clientName = appointmentEntity.clientName;
  //   } else {
  //     // Para citas normales, usar el subject
  //     final parts = appointment.subject.split('\n');
  //     clientName = parts.isNotEmpty ? parts[0] : '';
  //     serviceText = parts.length > 1 ? parts[1] : '';
  //   }

  //   // Calcular el color base y los bordes según la posición de la subcita
  //   final baseColor = appointment.color;
  //   final bool isFirstSubAppointment = subAppointmentIndex == 0;
  //   final bool isLastSubAppointment =
  //       subAppointmentIndex == totalSubAppointments - 1;

  //   // Nueva aproximación: Diseño unificado con gradiente para múltiples servicios
  //   return GestureDetector(
  //     onTap: () => showAppointmentDetails(context, appointmentEntity),
  //     child: Container(
  //       constraints: const BoxConstraints(
  //         minHeight: 32,
  //       ),
  //       margin: EdgeInsets.symmetric(
  //         horizontal: 3,
  //         vertical: isSubAppointment ? 0.25 : 3,
  //       ),
  //       decoration: BoxDecoration(
  //         // Gradiente suave para subcitas, color sólido para citas simples
  //         gradient: isSubAppointment
  //             ? LinearGradient(
  //                 begin: Alignment.topCenter,
  //                 end: Alignment.bottomCenter,
  //                 colors: [
  //                   baseColor,
  //                   Color.lerp(baseColor,
  //                       isLastSubAppointment ? Colors.white : baseColor, 0.1)!,
  //                 ],
  //               )
  //             : null,
  //         color: isSubAppointment ? null : baseColor,
  //         borderRadius: isSubAppointment
  //             ? _getSubAppointmentBorderRadius(
  //                 subAppointmentIndex, totalSubAppointments)
  //             : BorderRadius.circular(8),
  //         boxShadow: [
  //           BoxShadow(
  //             color: Colors.black.withOpacity(isSubAppointment ? 0.08 : 0.15),
  //             blurRadius: isSubAppointment ? 2 : 4,
  //             offset: Offset(0, isSubAppointment ? 1 : 2),
  //           ),
  //         ],
  //       ),
  //       child: Stack(
  //         children: [
  //           // Contenedor principal con información de la cita
  //           Padding(
  //             padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
  //             child: Row(
  //               children: [
  //                 // Columna principal con información de servicio y cliente
  //                 Expanded(
  //                   child: Column(
  //                     mainAxisAlignment: MainAxisAlignment.center,
  //                     crossAxisAlignment: CrossAxisAlignment.start,
  //                     mainAxisSize: MainAxisSize.min,
  //                     children: [
  //                       Text(
  //                         serviceText,
  //                         style: const TextStyle(
  //                           color: Colors.white,
  //                           fontSize: 12,
  //                           fontWeight: FontWeight.bold,
  //                           letterSpacing: 0.1,
  //                         ),
  //                         maxLines: 1,
  //                         overflow: TextOverflow.ellipsis,
  //                       ),
  //                       const SizedBox(height: 2),
  //                       Text(
  //                         clientName,
  //                         style: TextStyle(
  //                           color: Colors.white.withOpacity(0.85),
  //                           fontSize: 11,
  //                         ),
  //                         maxLines: 1,
  //                         overflow: TextOverflow.ellipsis,
  //                       ),
  //                     ],
  //                   ),
  //                 ),

  //                 // Para citas múltiples, mostrar indicador de servicio
  //                 if (totalSubAppointments > 1)
  //                   Container(
  //                     padding: const EdgeInsets.symmetric(
  //                         horizontal: 6, vertical: 2),
  //                     margin: const EdgeInsets.only(left: 4),
  //                     decoration: BoxDecoration(
  //                       color: Colors.white.withOpacity(0.2),
  //                       borderRadius: BorderRadius.circular(12),
  //                     ),
  //                     child: Text(
  //                       isSubAppointment
  //                           ? "${subAppointmentIndex + 1}/$totalSubAppointments"
  //                           : "1/$totalSubAppointments",
  //                       style: const TextStyle(
  //                         color: Colors.white,
  //                         fontSize: 9,
  //                         fontWeight: FontWeight.bold,
  //                       ),
  //                     ),
  //                   ),
  //               ],
  //             ),
  //           ),

  //           // Indicador de estado unificado (sólo en la primera subcita o cita única)
  //           if (isFirstSubAppointment || !isSubAppointment)
  //             Positioned(
  //               top: 0,
  //               right: 0,
  //               child: Container(
  //                 width: 12,
  //                 height: 12,
  //                 margin: const EdgeInsets.all(6),
  //                 decoration: BoxDecoration(
  //                   color: appointmentEntity.getStatusColor(),
  //                   shape: BoxShape.circle,
  //                   border: Border.all(
  //                     color: Colors.white,
  //                     width: 1.5,
  //                   ),
  //                   boxShadow: [
  //                     BoxShadow(
  //                       color:
  //                           appointmentEntity.getStatusColor().withOpacity(0.4),
  //                       blurRadius: 3,
  //                       spreadRadius: 1,
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //             ),

  //           // Línea decorativa lateral para subcitas (da sensación de unidad)
  //           if (isSubAppointment)
  //             Positioned(
  //               top: 0,
  //               bottom: 0,
  //               left: 0,
  //               child: Container(
  //                 width: 3,
  //                 decoration: BoxDecoration(
  //                   color: appointmentEntity.getStatusColor(),
  //                   borderRadius: BorderRadius.only(
  //                     topLeft: isFirstSubAppointment
  //                         ? const Radius.circular(8)
  //                         : Radius.zero,
  //                     bottomLeft: isLastSubAppointment
  //                         ? const Radius.circular(8)
  //                         : Radius.zero,
  //                   ),
  //                 ),
  //               ),
  //             ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  Widget _buildAppointment(
      BuildContext context, CalendarAppointmentDetails details) {
    final appointment = details.appointments.first;
    final String appointmentId = appointment.id?.toString() ?? '';

    // Verificar si es una subcita (contiene "_")
    final bool isSubAppointment = appointmentId.contains('_');

    // Obtener el ID de la cita principal y el índice de la subcita
    String mainAppointmentId = appointmentId;
    int subAppointmentIndex = -1;
    int totalSubAppointments = 1;

    if (isSubAppointment) {
      final parts = appointmentId.split('_');
      if (parts.length > 1) {
        mainAppointmentId = parts[0];
        subAppointmentIndex = int.tryParse(parts[1]) ?? -1;
      }

      // Contar cuántas subcitas hay para esta cita principal
      totalSubAppointments = controller.appointments
              .where((app) => app.id == mainAppointmentId)
              .firstOrNull
              ?.serviceTypes
              .length ??
          1;
    }

    // Buscar la cita principal
    final appointmentEntity = controller.appointments
        .firstWhereOrNull((app) => app.id == mainAppointmentId);

    if (appointmentEntity == null) return const SizedBox.shrink();

    // Determinar colores basados en el estado de pago
    final bool isPaid = appointmentEntity.isPaymentCompleted;

    final Color statusColor = isPaid
        ? appointmentEntity.getPaymentStatusColor()
        : appointmentEntity.getStatusColor();

    final Color appointmentBaseColor = isPaid
        ? Color.lerp(appointment.color, Colors.green, 0.15) ?? appointment.color
        : appointment.color;

    // Vista Mensual
    if (controller.currentView.value == CalendarView.month) {
      return GestureDetector(
        onTap: () => showAppointmentDetails(context, appointmentEntity),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            color: appointmentBaseColor,
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isSubAppointment
                          ? appointmentEntity.serviceTypes.join(', ')
                          : appointment.subject.split('\n').isNotEmpty
                              ? appointment.subject.split('\n')[0]
                              : '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      DateFormat('h:mm a')
                          .format(appointment.startTime.toLocal()),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Indicador de estado unificado para la cita
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 0.5,
                    ),
                  ),
                ),
              ),
              // Añadir indicador de pago si corresponde
              if (isPaid)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 0.5,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    // Vista diaria/semanal con enfoque en citas múltiples
    String serviceText = '';
    String clientName = '';

    if (isSubAppointment) {
      // Para subcitas, extraer el servicio específico
      if (subAppointmentIndex >= 0 &&
          subAppointmentIndex < appointmentEntity.serviceTypes.length) {
        serviceText = appointmentEntity.serviceTypes[subAppointmentIndex];
      }
      clientName = appointmentEntity.clientName;
    } else {
      // Para citas normales, usar el subject
      final parts = appointment.subject.split('\n');
      clientName = parts.isNotEmpty ? parts[0] : '';
      serviceText = parts.length > 1 ? parts[1] : '';
    }

    // Determinar si esta es la primera o última subcita
    final bool isFirstSubAppointment = subAppointmentIndex == 0;
    final bool isLastSubAppointment =
        subAppointmentIndex == totalSubAppointments - 1;

    // Obtener el color de borde lateral según estado de pago
    final Color borderColor = isPaid ? Colors.green : statusColor;

    // Diseño unificado con gradiente para múltiples servicios
    return GestureDetector(
      onTap: () => showAppointmentDetails(context, appointmentEntity),
      child: Container(
        constraints: const BoxConstraints(
          minHeight: 32,
        ),
        margin: EdgeInsets.symmetric(
          horizontal: 3,
          vertical: isSubAppointment ? 0.25 : 3,
        ),
        decoration: BoxDecoration(
          // Gradiente suave para subcitas, color sólido para citas simples
          gradient: isSubAppointment
              ? LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    appointmentBaseColor,
                    Color.lerp(
                        appointmentBaseColor,
                        isLastSubAppointment
                            ? Colors.white
                            : appointmentBaseColor,
                        0.1)!,
                  ],
                )
              : null,
          color: isSubAppointment ? null : appointmentBaseColor,
          borderRadius: isSubAppointment
              ? _getSubAppointmentBorderRadius(
                  subAppointmentIndex, totalSubAppointments)
              : BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isSubAppointment ? 0.08 : 0.15),
              blurRadius: isSubAppointment ? 2 : 4,
              offset: Offset(0, isSubAppointment ? 1 : 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Contenedor principal con información de la cita
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Row(
                children: [
                  // Columna principal con información de servicio y cliente
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          serviceText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.1,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          clientName,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        // Eliminado la línea que mostraba el profesional
                      ],
                    ),
                  ),

                  // Para citas múltiples, mostrar indicador de servicio
                  if (totalSubAppointments > 1)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      margin: const EdgeInsets.only(left: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isSubAppointment
                            ? "${subAppointmentIndex + 1}/$totalSubAppointments"
                            : "1/$totalSubAppointments",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Indicador de estado (solo en la primera subcita o cita única)
            if (isFirstSubAppointment || !isSubAppointment)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: statusColor.withOpacity(0.4),
                        blurRadius: 3,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),

            // Línea decorativa lateral para subcitas (ahora usa el statusColor)
            if (isSubAppointment)
              Positioned(
                top: 0,
                bottom: 0,
                left: 0,
                child: Container(
                  width: 3,
                  decoration: BoxDecoration(
                    color: borderColor,
                    borderRadius: BorderRadius.only(
                      topLeft: isFirstSubAppointment
                          ? const Radius.circular(8)
                          : Radius.zero,
                      bottomLeft: isLastSubAppointment
                          ? const Radius.circular(8)
                          : Radius.zero,
                    ),
                  ),
                ),
              ),

            // Indicador de pago (solo en la primera subcita o cita única)
            if ((isFirstSubAppointment || !isSubAppointment) && isPaid)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  margin: const EdgeInsets.only(right: 6, bottom: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.white,
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(
                        Icons.check_circle,
                        size: 8,
                        color: Colors.white,
                      ),
                      SizedBox(width: 2),
                      Text(
                        "PAGADO",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  BorderRadius _getSubAppointmentBorderRadius(int index, int total) {
    if (total <= 1 || index < 0) {
      return BorderRadius.circular(8);
    }

    if (index == 0) {
      // Primera subcita: bordes redondeados arriba
      return const BorderRadius.only(
        topLeft: Radius.circular(8),
        topRight: Radius.circular(8),
        bottomLeft: Radius.circular(1),
        bottomRight: Radius.circular(1),
      );
    } else if (index == total - 1) {
      // Última subcita: bordes redondeados abajo
      return const BorderRadius.only(
        topLeft: Radius.circular(1),
        topRight: Radius.circular(1),
        bottomLeft: Radius.circular(8),
        bottomRight: Radius.circular(8),
      );
    } else {
      // Subcitas intermedias: bordes mínimos
      return BorderRadius.circular(1);
    }
  }
}
