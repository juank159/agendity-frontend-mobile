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

    // Vista Mensual
    if (controller.currentView.value == CalendarView.month) {
      return GestureDetector(
        onTap: () => _showAppointmentDetails(context, appointmentEntity),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            color: appointment.color,
            borderRadius: BorderRadius.circular(2),
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

    // Vista diaria/semanal con estilo unificado para citas múltiples
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

    return GestureDetector(
      onTap: () => _showAppointmentDetails(context, appointmentEntity),
      child: Container(
        constraints: BoxConstraints(
          minHeight: 30,
        ),
        decoration: BoxDecoration(
          color: appointment.color,
          borderRadius: _getBorderRadiusForSubAppointment(
              subAppointmentIndex, totalSubAppointments),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
          // Borde superior e inferior para mostrar continuidad entre subcitas
          border: _getBorderForSubAppointment(
              subAppointmentIndex, totalSubAppointments, appointment.color),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            // Indicador numérico para subcitas (1/3, 2/3, etc.)
            if (isSubAppointment && totalSubAppointments > 1)
              Container(
                padding: EdgeInsets.all(4),
                margin: EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  "${subAppointmentIndex + 1}/$totalSubAppointments",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
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
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    clientName,
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
            // Solo mostrar indicador de estado en la primera subcita
            if (!isSubAppointment || subAppointmentIndex == 0)
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
                      color:
                          appointmentEntity.getStatusColor().withOpacity(0.4),
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

// Función para obtener bordes redondeados solo en los extremos de las subcitas
  BorderRadius _getBorderRadiusForSubAppointment(int index, int total) {
    if (total <= 1 || index < 0) {
      // Cita simple o desconocida: bordes redondeados en todos lados
      return BorderRadius.circular(8);
    }

    if (index == 0) {
      // Primera subcita: bordes redondeados arriba
      return BorderRadius.vertical(
        top: Radius.circular(8),
        bottom: Radius.circular(2),
      );
    } else if (index == total - 1) {
      // Última subcita: bordes redondeados abajo
      return BorderRadius.vertical(
        top: Radius.circular(2),
        bottom: Radius.circular(8),
      );
    } else {
      // Subcitas intermedias: bordes mínimos
      return BorderRadius.circular(2);
    }
  }

// Función para obtener bordes que muestren continuidad
  Border? _getBorderForSubAppointment(int index, int total, Color color) {
    if (total <= 1 || index < 0) {
      // Cita simple o desconocida: sin bordes especiales
      return null;
    }

    Color borderColor = color.withOpacity(0.7);

    if (index == 0) {
      // Primera subcita: borde inferior
      return Border(
        bottom: BorderSide(
          color: borderColor,
          width: 1.0,
          style: BorderStyle.solid,
        ),
      );
    } else if (index == total - 1) {
      // Última subcita: borde superior
      return Border(
        top: BorderSide(
          color: borderColor,
          width: 1.0,
          style: BorderStyle.solid,
        ),
      );
    } else {
      // Subcitas intermedias: bordes arriba y abajo
      return Border(
        top: BorderSide(
          color: borderColor,
          width: 1.0,
          style: BorderStyle.solid,
        ),
        bottom: BorderSide(
          color: borderColor,
          width: 1.0,
          style: BorderStyle.solid,
        ),
      );
    }
  }

// Función auxiliar para obtener el color del servicio
  Color _getServiceColor(AppointmentEntity entity, int index) {
    if (entity.colors != null && index < entity.colors!.length) {
      try {
        final colorStr = entity.colors![index].replaceAll('#', '');
        return Color(int.parse('FF$colorStr', radix: 16));
      } catch (e) {
        print('Error al convertir color: $e');
      }
    }
    return entity.getPrimaryColor();
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
