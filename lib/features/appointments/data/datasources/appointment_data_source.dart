import 'package:login_signup/features/appointments/domain/entities/appointment_entity.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class AppointmentDataSource extends CalendarDataSource {
  AppointmentDataSource(List<AppointmentEntity> appointments) {
    this.appointments = appointments.map((appointment) {
      return Appointment(
        startTime: appointment.startTime.toLocal(),
        endTime: appointment.endTime.toLocal(),
        subject:
            '${appointment.serviceTypes.join(", ")}\n${appointment.clientName}',
        color: appointment.getPrimaryColor(),
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
