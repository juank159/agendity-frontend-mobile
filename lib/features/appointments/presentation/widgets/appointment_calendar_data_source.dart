import 'package:flutter/material.dart';
import 'package:login_signup/features/appointments/domain/entities/appointment_entity.dart';
import 'package:login_signup/features/appointments/presentation/widgets/appointment_status_ui.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

/// Citas para el calendario de Syncfusion. Una cita con varios servicios se
/// pinta como bloques seguidos, uno por servicio, con su duración y su color;
/// el id de cada bloque es `<idCita>_<índice>`.
class AppointmentCalendarDataSource extends CalendarDataSource {
  AppointmentCalendarDataSource(List<AppointmentEntity> appointments) {
    this.appointments = [
      for (final entity in appointments) ..._blocksOf(entity),
    ];
  }

  static List<Appointment> _blocksOf(AppointmentEntity entity) {
    if (entity.services.length <= 1) {
      return [
        Appointment(
          startTime: entity.startTime,
          endTime: entity.endTime,
          subject: entity.services.isEmpty
              ? entity.clientName
              : '${entity.clientName}\n${entity.services.first.name}',
          color: entity.primaryColor,
          notes: entity.notes,
          id: entity.id,
        ),
      ];
    }
    final blocks = <Appointment>[];
    var start = entity.startTime;
    for (var i = 0; i < entity.services.length; i++) {
      final service = entity.services[i];
      final end = start.add(Duration(minutes: service.durationMinutes));
      blocks.add(Appointment(
        startTime: start,
        endTime: end,
        subject: '${entity.clientName}\n${service.name}',
        color: entity.serviceColor(i),
        notes: entity.notes,
        id: '${entity.id}_$i',
      ));
      start = end;
    }
    return blocks;
  }

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
