import 'dart:ui';

import 'package:login_signup/features/appointments/domain/entities/appointment_entity.dart';

import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:get/get.dart';
import 'package:login_signup/features/appointments/presentation/controllers/appointments_controller.dart';

class AppointmentDataSource extends CalendarDataSource {
  AppointmentDataSource(List<AppointmentEntity> appointments) {
    print('== CREANDO APPOINTMENT DATA SOURCE (VERSIÓN FINAL OPTIMIZADA) ==');
    print('Citas originales: ${appointments.length}');

    List<Appointment> result = [];

    // Intentar obtener el controlador de citas para acceder a la información de servicios
    AppointmentsController? appointmentsController;
    try {
      appointmentsController = Get.find<AppointmentsController>();
      print(
          'Controlador de citas encontrado con ${appointmentsController.services.length} servicios');
    } catch (e) {
      print('No se pudo obtener el controlador de citas: $e');
    }

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

          // Obtener duraciones reales desde el controlador si es posible
          List<int> serviceDurations = [];

          if (appointmentsController != null) {
            // Buscar la duración de cada servicio en el controlador
            for (String serviceType in entity.serviceTypes) {
              // Buscar el servicio por nombre
              final serviceInfo = appointmentsController.services
                  .firstWhereOrNull(
                      (service) => service['name'] == serviceType);

              int duration = 30; // Duración predeterminada en minutos

              if (serviceInfo != null && serviceInfo['duration'] != null) {
                // Convertir duración a entero
                try {
                  duration = int.parse(serviceInfo['duration'].toString());
                } catch (e) {
                  print('Error al convertir duración para $serviceType: $e');
                }
              }

              serviceDurations.add(duration);
              print('  → Duración para $serviceType: $duration minutos');
            }
          } else {
            // Si no hay controlador, dividir tiempo equitativamente
            int perServiceDuration = totalMinutes ~/ entity.serviceTypes.length;
            serviceDurations =
                List.filled(entity.serviceTypes.length, perServiceDuration);
            print(
                '  → Sin datos de duración reales, asignando $perServiceDuration minutos por servicio');
          }

          // Calcular suma total de duraciones esperadas
          int totalEstimatedDuration = serviceDurations.reduce((a, b) => a + b);
          print(
              '• Suma de duraciones esperadas: $totalEstimatedDuration minutos');

          // Ajustar proporcionalmente para que coincida con el tiempo total
          List<int> adjustedDurations = [];

          if (totalEstimatedDuration > 0) {
            // Calcular el factor de ajuste
            double scaleFactor = totalMinutes / totalEstimatedDuration;
            print('• Factor de ajuste: $scaleFactor');

            // Aplicar el factor de escala a cada duración
            for (int duration in serviceDurations) {
              int adjustedDuration = (duration * scaleFactor).round();
              adjustedDurations.add(adjustedDuration);
            }

            // Corregir cualquier diferencia por redondeo
            int sum = adjustedDurations.reduce((a, b) => a + b);
            int diff = totalMinutes - sum;

            if (diff != 0) {
              // Distribuir la diferencia entre los servicios, comenzando por los más largos
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

            // Distribuir los minutos sobrantes
            int remaining = totalMinutes -
                (perServiceDuration * entity.serviceTypes.length);
            for (int i = 0; i < remaining; i++) {
              adjustedDurations[i]++;
            }
          }

          // Mostrar duraciones ajustadas finales
          print('• Duraciones ajustadas finales:');
          for (int i = 0; i < entity.serviceTypes.length; i++) {
            print(
                '  → ${entity.serviceTypes[i]}: ${adjustedDurations[i]} minutos');
          }

          // Crear subcitas con las duraciones ajustadas
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
              } catch (e) {
                print('Error al procesar color: $e');
              }
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
