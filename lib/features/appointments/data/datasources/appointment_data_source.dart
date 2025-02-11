// appointment_data_source.dart
import 'package:flutter/material.dart';
import 'package:login_signup/features/appointments/domain/entities/appointment_entity.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class AppointmentDataSource extends CalendarDataSource {
  AppointmentDataSource(List<AppointmentEntity> appointments) {
    this.appointments = appointments.map((appointment) {
      Color appointmentColor;
      try {
        if (appointment.color != null) {
          final colorStr = appointment.color!.replaceAll('#', '');
          appointmentColor = Color(int.parse('FF$colorStr', radix: 16));
        } else {
          appointmentColor = Colors.orange;
        }
      } catch (e) {
        appointmentColor = Colors.orange;
      }

      return Appointment(
        startTime: appointment.startTime.toLocal(),
        endTime: appointment.endTime.toLocal(),
        subject: '${appointment.serviceType}\n${appointment.clientName}',
        color: appointmentColor,
        notes: appointment.notes,
        id: appointment.id,
      );
    }).toList();
  }

  @override
  DateTime getStartTime(int index) {
    return appointments![index].startTime.toLocal();
  }

  @override
  DateTime getEndTime(int index) {
    return appointments![index].endTime.toLocal();
  }
}
