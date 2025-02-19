// import 'dart:ui';

// import 'package:login_signup/features/appointments/domain/entities/appointment_entity.dart';
// import 'package:login_signup/features/appointments/data/models/appointment_model.dart';
// import 'package:syncfusion_flutter_calendar/calendar.dart';
// import 'package:get/get.dart';
// import 'package:login_signup/features/appointments/presentation/controllers/appointments_controller.dart';

// class AppointmentDataSource extends CalendarDataSource {
//   AppointmentDataSource(List<AppointmentEntity> appointments) {
//     print('== CREANDO APPOINTMENT DATA SOURCE (VERSIÓN COMPARATIVA) ==');
//     print('Citas originales: ${appointments.length}');

//     List<Appointment> result = [];

//     // Obtener el controlador
//     AppointmentsController? controller;
//     try {
//       controller = Get.find<AppointmentsController>();
//       print('==== SERVICIOS DISPONIBLES EN CONTROLADOR ====');
//       for (var service in controller.services) {
//         print(
//             '• ID: ${service['id']}, Nombre: ${service['name']}, Duración: ${service['duration']}, Color: ${service['color']}');
//       }
//       print('==========================================');
//     } catch (e) {
//       print('No se pudo obtener el controlador: $e');
//     }

//     // Procesar cada cita
//     for (var entity in appointments) {
//       print('\n>>>>>>> ANALIZANDO CITA: ${entity.id} <<<<<<<<<');
//       print('Tipo: ${entity.serviceTypes.length <= 1 ? "SIMPLE" : "MÚLTIPLE"}');
//       print('Rango total: ${entity.startTime} - ${entity.endTime}');
//       print(
//           'Duración total: ${entity.endTime.difference(entity.startTime).inMinutes} minutos');
//       print('Servicios: ${entity.serviceTypes.join(", ")}');

//       // Obtener información de serviceIds
//       List<String> serviceIds = [];
//       if (entity is AppointmentModel) {
//         serviceIds = entity.serviceIds;
//         print('ServiceIds: $serviceIds');
//       }

//       // Para todas las citas (simples y múltiples), obtener información completa de cada servicio
//       List<Map<String, dynamic>> servicesInfo = [];

//       if (serviceIds.isNotEmpty && controller != null) {
//         for (int i = 0; i < serviceIds.length; i++) {
//           String serviceId = serviceIds[i];
//           var serviceInfo =
//               controller.services.firstWhereOrNull((s) => s['id'] == serviceId);

//           if (serviceInfo != null) {
//             int duration = 0;
//             if (serviceInfo['duration'] != null) {
//               if (serviceInfo['duration'] is int) {
//                 duration = serviceInfo['duration'];
//               } else {
//                 duration =
//                     int.tryParse(serviceInfo['duration'].toString()) ?? 0;
//               }
//             }

//             servicesInfo.add({
//               'id': serviceId,
//               'name': serviceInfo['name'],
//               'duration': duration,
//               'color': serviceInfo['color'],
//             });

//             print('SERVICIO ${i + 1}: ${serviceInfo['name']}');
//             print('  • Duración en BD: $duration minutos');
//             print('  • Color: ${serviceInfo['color']}');
//           } else {
//             print('SERVICIO ${i + 1}: No encontrado (ID: $serviceId)');
//             servicesInfo.add({
//               'id': serviceId,
//               'name': i < entity.serviceTypes.length
//                   ? entity.serviceTypes[i]
//                   : 'Desconocido',
//               'duration': 0,
//               'color': null,
//             });
//           }
//         }
//       } else if (entity.serviceTypes.isNotEmpty && controller != null) {
//         // Buscar por nombre
//         for (int i = 0; i < entity.serviceTypes.length; i++) {
//           String serviceName = entity.serviceTypes[i];
//           var serviceInfo = controller.services
//               .firstWhereOrNull((s) => s['name']?.toString() == serviceName);

//           if (serviceInfo != null) {
//             int duration = 0;
//             if (serviceInfo['duration'] != null) {
//               if (serviceInfo['duration'] is int) {
//                 duration = serviceInfo['duration'];
//               } else {
//                 duration =
//                     int.tryParse(serviceInfo['duration'].toString()) ?? 0;
//               }
//             }

//             servicesInfo.add({
//               'id': serviceInfo['id'],
//               'name': serviceName,
//               'duration': duration,
//               'color': serviceInfo['color'],
//             });

//             print('SERVICIO ${i + 1}: $serviceName');
//             print('  • Duración en BD: $duration minutos');
//             print('  • Color: ${serviceInfo['color']}');
//           } else {
//             print('SERVICIO ${i + 1}: $serviceName (no encontrado en BD)');
//             servicesInfo.add({
//               'id': null,
//               'name': serviceName,
//               'duration': 0,
//               'color': null,
//             });
//           }
//         }
//       }

//       // Procesar cita según si es simple o múltiple
//       if (entity.serviceTypes.isEmpty || entity.serviceTypes.length == 1) {
//         // CITA SIMPLE - Analizar cómo se manejan las citas de un solo servicio
//         Appointment appointment = Appointment(
//           startTime: entity.startTime,
//           endTime: entity.endTime,
//           subject: entity.serviceTypes.isEmpty
//               ? entity.clientName
//               : '${entity.clientName}\n${entity.serviceTypes[0]}',
//           color: entity.getPrimaryColor(),
//           notes: entity.notes,
//           id: entity.id,
//           isAllDay: false,
//         );

//         result.add(appointment);

//         int actualDuration =
//             entity.endTime.difference(entity.startTime).inMinutes;
//         int serviceDuration =
//             servicesInfo.isNotEmpty ? servicesInfo[0]['duration'] : 0;

//         print('CITA SIMPLE CREADA: ${entity.id}');
//         print('• Duración real de la cita: $actualDuration minutos');
//         print('• Duración del servicio en BD: $serviceDuration minutos');
//         print('• Método usado: Usar exactamente el rango de tiempo programado');
//       } else {
//         // CITA MÚLTIPLE - Aplicar mismo método que usan las citas simples
//         try {
//           print('CREANDO CITA MÚLTIPLE CON MISMO ENFOQUE QUE CITAS SIMPLES');

//           // El secreto: usar la duración total exacta de la cita y crear subcitas con esa duración
//           final totalDuration =
//               entity.endTime.difference(entity.startTime).inMinutes;

//           // 1. Calcular duraciones proporcionales si es posible
//           List<int> durations = [];
//           int totalDBDuration = 0;

//           // Sumar duraciones de BD
//           for (var service in servicesInfo) {
//             totalDBDuration += service['duration'] as int;
//           }

//           print('• Duración total de la cita: $totalDuration minutos');
//           print('• Suma de duraciones en BD: $totalDBDuration minutos');

//           // Calcular duraciones finales
//           if (totalDBDuration > 0) {
//             // Usar proporción según la BD
//             for (var service in servicesInfo) {
//               int dbDuration = service['duration'] as int;
//               // Usar regla de tres: si totalDBDuration = 100%, dbDuration = x%
//               int calculatedDuration = 0;
//               if (dbDuration > 0) {
//                 calculatedDuration =
//                     (dbDuration / totalDBDuration * totalDuration).round();
//               } else {
//                 calculatedDuration = totalDuration ~/ servicesInfo.length;
//               }
//               durations.add(calculatedDuration);
//             }
//           } else {
//             // Si no hay duraciones en BD, dividir equitativamente
//             int perServiceDuration =
//                 totalDuration ~/ entity.serviceTypes.length;
//             durations =
//                 List.filled(entity.serviceTypes.length, perServiceDuration);
//           }

//           // Ajustar para que sumen exactamente el total
//           int sumDurations = durations.reduce((a, b) => a + b);
//           if (sumDurations != totalDuration) {
//             int diff = totalDuration - sumDurations;
//             durations[durations.length - 1] += diff;
//           }

//           // Mostrar duraciones calculadas
//           print('• Duraciones calculadas:');
//           for (int i = 0; i < entity.serviceTypes.length; i++) {
//             print('  → ${entity.serviceTypes[i]}: ${durations[i]} minutos');
//           }

//           // 2. Crear subcitas
//           DateTime startTime = entity.startTime;

//           for (int i = 0; i < entity.serviceTypes.length; i++) {
//             // Calcular hora de fin
//             DateTime endTime = startTime.add(Duration(minutes: durations[i]));

//             // Asegurar que no se pase del tiempo total
//             if (endTime.isAfter(entity.endTime)) {
//               endTime = entity.endTime;
//             }

//             // Determinar color
//             Color color = entity.getPrimaryColor();
//             if (i < servicesInfo.length && servicesInfo[i]['color'] != null) {
//               try {
//                 String colorStr =
//                     servicesInfo[i]['color'].toString().replaceAll('#', '');
//                 color = Color(int.parse('FF$colorStr', radix: 16));
//               } catch (e) {/* usar color por defecto */}
//             } else if (entity.colors != null && i < entity.colors!.length) {
//               try {
//                 String colorStr = entity.colors![i].replaceAll('#', '');
//                 color = Color(int.parse('FF$colorStr', radix: 16));
//               } catch (e) {/* usar color por defecto */}
//             }

//             // Crear subcita
//             Appointment appointment = Appointment(
//               startTime: startTime,
//               endTime: endTime,
//               subject: '${entity.clientName}\n${entity.serviceTypes[i]}',
//               color: color,
//               id: '${entity.id}_$i',
//               notes: entity.notes,
//               isAllDay: false,
//             );

//             result.add(appointment);

//             print('SUBCITA ${i + 1} CREADA:');
//             print('• Horario: $startTime - $endTime');
//             print('• Servicio: ${entity.serviceTypes[i]}');
//             print(
//                 '• Duración: ${endTime.difference(startTime).inMinutes} minutos');

//             // Actualizar startTime para el siguiente servicio
//             startTime = endTime;
//           }
//         } catch (e) {
//           print('ERROR PROCESANDO CITA MÚLTIPLE: $e');
//           print('CREANDO CITA SIMPLE COMO FALLBACK');

//           // Fallback: crear cita simple
//           result.add(Appointment(
//             startTime: entity.startTime,
//             endTime: entity.endTime,
//             subject: '${entity.clientName}\n${entity.serviceTypes.join(", ")}',
//             color: entity.getPrimaryColor(),
//             notes: entity.notes,
//             id: entity.id,
//             isAllDay: false,
//           ));
//         }
//       }

//       print('>>>>>>> FIN ANÁLISIS CITA: ${entity.id} <<<<<<<<<\n');
//     }

//     this.appointments = result;
//     print('Total citas procesadas: ${result.length}');
//   }

//   // Métodos obligatorios para el CalendarDataSource
//   @override
//   DateTime getStartTime(int index) {
//     return appointments![index].startTime;
//   }

//   @override
//   DateTime getEndTime(int index) {
//     return appointments![index].endTime;
//   }

//   @override
//   String getSubject(int index) {
//     return appointments![index].subject;
//   }

//   @override
//   Color getColor(int index) {
//     return appointments![index].color;
//   }

//   @override
//   bool isAllDay(int index) {
//     return appointments![index].isAllDay;
//   }

//   @override
//   String? getNotes(int index) {
//     return appointments![index].notes;
//   }

//   @override
//   String? getId(int index) {
//     return appointments![index].id;
//   }
// }

import 'dart:ui';

import 'package:login_signup/features/appointments/domain/entities/appointment_entity.dart';
import 'package:login_signup/features/appointments/data/models/appointment_model.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:get/get.dart';
import 'package:login_signup/features/appointments/presentation/controllers/appointments_controller.dart';

class AppointmentDataSource extends CalendarDataSource {
  AppointmentDataSource(List<AppointmentEntity> appointments) {
    print('== CREANDO APPOINTMENT DATA SOURCE (VERSIÓN FINAL OPTIMIZADA) ==');
    print('Citas originales: ${appointments.length}');

    List<Appointment> result = [];

    // Obtener el controlador
    AppointmentsController? controller;
    try {
      controller = Get.find<AppointmentsController>();
    } catch (e) {
      print('No se pudo obtener el controlador: $e');
    }

    // Constantes de duración real conocidas (basadas en las citas simples)
    final Map<String, int> realDurations = {
      'Pestañas 5D': 150, // 2h 30m basado en la cita simple
      'Pestañas Clásicas': 90, // 1h 30m
      'Pestañas 3D': 120, // 2h
      'Depilación de Cejas': 30, // 30m basado en la cita simple
      'Cejas semipermanentes': 45, // 45m estimado
      'Planchado': 60, // 1h estimado
      'Uñas acrilicas': 90, // 1h 30m estimado
    };

    for (var entity in appointments) {
      if (entity.serviceTypes.isEmpty || entity.serviceTypes.length == 1) {
        // CASO 1: Cita con un solo servicio - sin cambios
        result.add(Appointment(
          startTime: entity.startTime,
          endTime: entity.endTime,
          subject: entity.serviceTypes.isEmpty
              ? entity.clientName
              : '${entity.clientName}\n${entity.serviceTypes[0]}',
          color: entity.getPrimaryColor(),
          notes: entity.notes,
          id: entity.id,
          isAllDay: false,
        ));
      } else {
        try {
          // CASO 2: Cita con múltiples servicios
          print('\n• Procesando cita múltiple: ${entity.id}');
          print('• Servicios: ${entity.serviceTypes.join(", ")}');
          print('• Rango: ${entity.startTime} - ${entity.endTime}');

          final totalMinutes =
              entity.endTime.difference(entity.startTime).inMinutes;
          print('• Duración total: $totalMinutes minutos');

          // 1. Calcular la duración esperada de cada servicio (basada en duraciones reales)
          List<int> estimatedDurations = [];

          for (var serviceType in entity.serviceTypes) {
            int duration =
                realDurations[serviceType] ?? 30; // 30min por defecto
            estimatedDurations.add(duration);
            print('  → Duración esperada para $serviceType: $duration minutos');
          }

          // 2. Calcular suma total de duraciones estimadas
          int totalEstimatedDuration =
              estimatedDurations.reduce((a, b) => a + b);
          print(
              '• Suma de duraciones esperadas: $totalEstimatedDuration minutos');

          // 3. Ajustar las duraciones para que se ajusten al tiempo total programado
          List<int> adjustedDurations = [];

          if (totalEstimatedDuration > 0) {
            // Ajustar proporcionalmente
            double ratio = totalMinutes / totalEstimatedDuration;
            print('• Factor de ajuste: $ratio');

            for (int duration in estimatedDurations) {
              int adjustedDuration = (duration * ratio).round();
              adjustedDurations.add(adjustedDuration);
            }

            // Asegurar que la suma sea exactamente igual al tiempo total
            int sum = adjustedDurations.reduce((a, b) => a + b);
            if (sum != totalMinutes) {
              int diff = totalMinutes - sum;
              // Distribuir la diferencia empezando por los servicios más largos
              List<int> indices =
                  List.generate(adjustedDurations.length, (i) => i);
              indices.sort((a, b) =>
                  adjustedDurations[b].compareTo(adjustedDurations[a]));

              int i = 0;
              while (diff != 0) {
                if (diff > 0) {
                  adjustedDurations[indices[i % indices.length]]++;
                  diff--;
                } else {
                  if (adjustedDurations[indices[i % indices.length]] > 1) {
                    adjustedDurations[indices[i % indices.length]]--;
                    diff++;
                  }
                }
                i++;
              }
            }
          } else {
            // Fallback: dividir el tiempo equitativamente
            int perServiceDuration = totalMinutes ~/ entity.serviceTypes.length;
            adjustedDurations =
                List.filled(entity.serviceTypes.length, perServiceDuration);
          }

          // 4. Mostrar duraciones ajustadas finales
          print('• Duraciones ajustadas finales:');
          for (int i = 0; i < entity.serviceTypes.length; i++) {
            print(
                '  → ${entity.serviceTypes[i]}: ${adjustedDurations[i]} minutos');
          }

          // 5. Crear subcitas con las duraciones ajustadas
          DateTime startTime = entity.startTime;

          for (int i = 0; i < entity.serviceTypes.length; i++) {
            // Calcular hora de fin
            DateTime endTime =
                startTime.add(Duration(minutes: adjustedDurations[i]));

            // Determinar color
            Color color = entity.getPrimaryColor();
            if (entity.colors != null && i < entity.colors!.length) {
              try {
                String colorStr = entity.colors![i].replaceAll('#', '');
                color = Color(int.parse('FF$colorStr', radix: 16));
              } catch (e) {/* usar color por defecto */}
            }

            // Crear subcita
            Appointment serviceAppointment = Appointment(
              startTime: startTime,
              endTime: endTime,
              subject: '${entity.clientName}\n${entity.serviceTypes[i]}',
              color: color,
              id: '${entity.id}_$i',
              notes: entity.notes,
              isAllDay: false,
            );

            result.add(serviceAppointment);
            print(
                '  Subcita creada: ${entity.serviceTypes[i]} (${startTime.hour}:${startTime.minute.toString().padLeft(2, '0')} - ${endTime.hour}:${endTime.minute.toString().padLeft(2, '0')})');

            // Actualizar hora de inicio para el siguiente servicio
            startTime = endTime;
          }
        } catch (e) {
          print('Error procesando cita múltiple: $e');
          // Fallback: crear cita simple
          result.add(Appointment(
            startTime: entity.startTime,
            endTime: entity.endTime,
            subject: '${entity.clientName}\n${entity.serviceTypes.join(", ")}',
            color: entity.getPrimaryColor(),
            notes: entity.notes,
            id: entity.id,
            isAllDay: false,
          ));
        }
      }
    }

    this.appointments = result;
    print('Total citas procesadas: ${result.length}');
  }

  // Métodos obligatorios para el CalendarDataSource
  @override
  DateTime getStartTime(int index) {
    return appointments![index].startTime;
  }

  @override
  DateTime getEndTime(int index) {
    return appointments![index].endTime;
  }

  @override
  String getSubject(int index) {
    return appointments![index].subject;
  }

  @override
  Color getColor(int index) {
    return appointments![index].color;
  }

  @override
  bool isAllDay(int index) {
    return appointments![index].isAllDay;
  }

  @override
  String? getNotes(int index) {
    return appointments![index].notes;
  }

  @override
  String? getId(int index) {
    return appointments![index].id;
  }
}
