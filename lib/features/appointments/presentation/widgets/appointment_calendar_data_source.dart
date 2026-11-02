import 'package:flutter/material.dart';
import 'package:login_signup/features/appointments/domain/entities/appointment_entity.dart';
import 'package:login_signup/features/appointments/presentation/widgets/appointment_status_ui.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

/// Citas para el calendario de Syncfusion: **un bloque por cita** (12.04),
/// de su inicio a su fin, aunque tenga varios servicios (la tarjeta
/// `AppointmentTile` pinta una píldora por servicio). El id del bloque es el
/// id de la cita.
class AppointmentCalendarDataSource extends CalendarDataSource {
  AppointmentCalendarDataSource(List<AppointmentEntity> appointments) {
    this.appointments = [for (final entity in appointments) _blockOf(entity)];
  }

  static Appointment _blockOf(AppointmentEntity entity) => Appointment(
        startTime: entity.startTime,
        endTime: entity.endTime,
        subject: [entity.clientName, ...entity.serviceNames].join('\n'),
        color: entity.primaryColor,
        notes: entity.notes,
        id: entity.id,
      );

  @override
  DateTime getStartTime(int index) => appointments![index].startTime;

  @override
  DateTime getEndTime(int index) => appointments![index].endTime;

  @override
  String getSubject(int index) => appointments![index].subject;

  @override
  Color getColor(int index) => appointments![index].color;

  @override
  bool isAllDay(int index) => appointments![index].isAllDay;

  @override
  String? getNotes(int index) => appointments![index].notes;

  @override
  Object? getId(int index) => appointments![index].id;
}
