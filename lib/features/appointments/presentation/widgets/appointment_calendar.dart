import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:login_signup/features/appointments/domain/entities/appointment_entity.dart';
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
      builder: (controller) => Column(
        children: [
          Expanded(
            child: SfCalendar(
              key: ValueKey('calendar-${controller.currentView.value}'),
              view: controller.currentView.value,
              dataSource: controller.getCalendarDataSource(),
              timeZone: 'UTC',
              onViewChanged: (ViewChangedDetails details) {
                Future.microtask(() => controller.onViewChanged(details));
              },
              initialDisplayDate: controller.selectedDate.value,
              headerHeight: 50,
              viewHeaderHeight: 60,
              allowViewNavigation: true,
              showNavigationArrow: true,
              showDatePickerButton: true,
              backgroundColor: Colors.white,
              todayHighlightColor: Theme.of(context).primaryColor,
              cellBorderColor: Colors.grey[300],
              firstDayOfWeek: 1,
              showCurrentTimeIndicator: true,
              onTap: (CalendarTapDetails details) {
                if (controller.currentView.value == CalendarView.month &&
                    details.targetElement == CalendarElement.calendarCell) {
                  // Si el tap fue en el día actual, usar la hora actual
                  final now = DateTime.now();
                  if (details.date?.year == now.year &&
                      details.date?.month == now.month &&
                      details.date?.day == now.day) {
                    controller.selectedDate.value = now;
                  } else {
                    // Si es otro día, usar la fecha seleccionada a mediodía
                    controller.selectedDate.value =
                        details.date ?? DateTime.now();
                  }
                  controller.changeView(CalendarView.day);
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

    // Vista Mensual
    if (controller.currentView.value == CalendarView.month) {
      return GestureDetector(
        onTap: () => _showAppointmentDetails(context, appointmentEntity),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            color: appointmentEntity.getPrimaryColor(),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      appointmentEntity.serviceTypes.join(', '),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      // Aquí es donde agregamos el formato de hora local
                      DateFormat('h:mm a')
                          .format(appointmentEntity.startTime.toLocal()),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9, // Tamaño más pequeño para la hora
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: appointmentEntity.getStatusColor(),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Vista diaria/semanal
    return GestureDetector(
      onTap: () => _showAppointmentDetails(context, appointmentEntity),
      child: Container(
        constraints: const BoxConstraints(
          minHeight: 30,
          maxHeight: 50,
        ),
        decoration: BoxDecoration(
          color: appointmentEntity.getPrimaryColor(),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    appointmentEntity.serviceTypes.join(', '),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    appointmentEntity.clientName,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.only(left: 8),
              decoration: BoxDecoration(
                color: appointmentEntity.getStatusColor(),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: appointmentEntity.getStatusColor().withOpacity(0.4),
                    blurRadius: 6,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAppointmentDetails(
      BuildContext context, AppointmentEntity appointment) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    appointment.getStatusText(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: appointment.getStatusColor(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.access_time),
                title: Text(DateFormat('dd/MM/yyyy')
                    .format(appointment.startTime.toLocal())),
                subtitle: Text(
                  '${DateFormat('h:mm a').format(appointment.startTime.toLocal())} - '
                  '${DateFormat('h:mm a').format(appointment.endTime.toLocal())}',
                ),
              ),
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Cliente'),
                subtitle: Text(appointment.clientName),
              ),
              ListTile(
                leading: const Icon(Icons.business_center),
                title: const Text('Servicios'),
                subtitle: Text(appointment.serviceTypes.join('\n')),
              ),
              if (appointment.notes?.isNotEmpty ?? false)
                ListTile(
                  leading: const Icon(Icons.note),
                  title: const Text('Notas'),
                  subtitle: Text(appointment.notes!),
                ),
              if (appointment.paymentStatus != null)
                ListTile(
                  leading: const Icon(Icons.payment),
                  title: const Text('Estado de pago'),
                  subtitle: Text(
                    appointment.getPaymentStatusText(),
                    style: TextStyle(
                      color: appointment.getPaymentStatusColor(),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ListTile(
                leading: const Icon(Icons.attach_money),
                title: const Text('Precio total'),
                subtitle: Text('\$${appointment.totalPrice}'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
