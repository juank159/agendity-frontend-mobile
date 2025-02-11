import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
      builder: (controller) => Stack(
        children: [
          SfCalendar(
            key: ValueKey('calendar-${controller.currentView.value}'),
            view: controller.currentView.value,
            dataSource: controller.getCalendarDataSource(),
            onViewChanged: (ViewChangedDetails details) {
              Future.microtask(() => controller.onViewChanged(details));
            },
            headerHeight: 50,
            viewHeaderHeight: 60,
            allowViewNavigation: true,
            showNavigationArrow: true,
            showDatePickerButton: true,
            backgroundColor: Colors.white,
            todayHighlightColor: Theme.of(context).primaryColor,
            cellBorderColor: Colors.grey[300],
            firstDayOfWeek: 1,

            // Configuración del encabezado
            headerStyle: CalendarHeaderStyle(
              textAlign: TextAlign.center,
              textStyle: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),

            // Configuración de la vista diaria y semanal
            timeSlotViewSettings: TimeSlotViewSettings(
              startHour: 6,
              endHour: 22,
              timeFormat: 'HH:mm',
              timeInterval: const Duration(minutes: 30),
              timeIntervalHeight: 80,
              timeTextStyle: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 15,
                color: Colors.grey[700],
              ),
              dateFormat: 'd',
              dayFormat: 'EEE', // Formato corto del día
              timeRulerSize: 70,
            ),

            // Configuración de la vista mensual
            monthViewSettings: MonthViewSettings(
              dayFormat: 'EEE', // Formato corto del día
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

            // Estilo para los encabezados de los días
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

            // Constructor de citas
            appointmentBuilder: _buildAppointment,
          ),
          if (controller.isLoading.value)
            Container(
              color: Colors.black12,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAppointment(
      BuildContext context, CalendarAppointmentDetails details) {
    final appointment = details.appointments.first;
    final appointmentEntity = controller.appointments.firstWhereOrNull(
      (app) => app.id == appointment.id,
    );

    if (appointmentEntity == null) return const SizedBox.shrink();

    if (controller.currentView.value == CalendarView.month) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 1),
        decoration: BoxDecoration(
          color: _getAppointmentColor(appointmentEntity.color),
          borderRadius: BorderRadius.circular(2),
        ),
        alignment: Alignment.center,
        child: Text(
          appointmentEntity.serviceType,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: _getAppointmentColor(appointmentEntity.color),
        borderRadius: BorderRadius.circular(4),
      ),
      padding: const EdgeInsets.all(4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            appointmentEntity.serviceType,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Flexible(
            child: Text(
              appointmentEntity.clientName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Color _getAppointmentColor(String? colorString) {
    if (colorString == null) return Colors.blue;
    try {
      if (colorString.startsWith('#')) {
        return Color(int.parse('0xFF${colorString.substring(1)}'));
      }
      switch (colorString.toLowerCase()) {
        case 'red':
          return Colors.red;
        case 'blue':
          return Colors.blue;
        case 'green':
          return Colors.green;
        case 'yellow':
          return Colors.yellow;
        case 'purple':
          return Colors.purple;
        case 'orange':
          return Colors.orange;
        default:
          return Colors.blue;
      }
    } catch (e) {
      return Colors.blue;
    }
  }
}
