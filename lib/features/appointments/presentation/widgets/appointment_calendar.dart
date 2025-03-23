import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:login_signup/features/appointments/presentation/widgets/appointment_detail_dialog.dart';
import 'package:login_signup/features/appointments/presentation/widgets/appointment_form_dialog.dart';

import 'package:syncfusion_flutter_calendar/calendar.dart';
import '../controllers/appointments_controller.dart';

class AppointmentCalendar extends StatelessWidget {
  final AppointmentsController controller;

  const AppointmentCalendar({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AppointmentsController>(
      id: 'calendar-view',
      builder: (controller) {
        print(
            'Reconstruyendo calendario con ${controller.appointments.length} citas');

        // Crear regiones de tiempo para indicar fechas pasadas
        final List<TimeRegion> timeRegions = [];

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
                      } else if (controller.currentView.value ==
                          CalendarView.day) {
                        // En vista diaria, verificar si la fecha no está en el pasado
                        if (!_isDateInPast(selectedDate)) {
                          // Llamar al diálogo de creación de cita con la fecha y hora seleccionada
                          AppointmentFormDialog.show(
                              context, controller, selectedDate);
                        } else {
                          // Notificar al usuario que no puede crear citas en el pasado
                          Get.snackbar(
                            'Fecha no válida',
                            'No se pueden crear citas en fechas pasadas',
                            backgroundColor: Colors.red[100],
                            colorText: Colors.red[800],
                            duration: const Duration(seconds: 3),
                            snackPosition: SnackPosition.TOP,
                          );
                        }
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
                  // INTERVALOS DE 30 MINUTOS
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
                  nonWorkingDays: const <int>[
                    DateTime.saturday,
                    DateTime.sunday
                  ],
                ),
                monthViewSettings: MonthViewSettings(
                  dayFormat: 'EEE',
                  showAgenda: false,
                  navigationDirection: MonthNavigationDirection.horizontal,
                  //appointmentDisplayMode: MonthAppointmentDisplayMode.indicator,
                  appointmentDisplayMode: MonthAppointmentDisplayMode.none,
                  appointmentDisplayCount: 0,
                  showTrailingAndLeadingDates: true,
                  numberOfWeeksInView: 6,
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
                monthCellBuilder: _buildMonthCell,
                // Eliminar las propiedades que causan errores:
                // cellBorder y timeRegionBuilder
                specialRegions: timeRegions,
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

  // Método para verificar si una fecha está en el pasado
  bool _isDateInPast(DateTime date) {
    final now = DateTime.now();
    return date.isBefore(now);
  }

  // Método para construir celdas mensuales personalizadas con contador de citas
  // Widget _buildMonthCell(BuildContext context, MonthCellDetails details) {
  //   // Obtener la fecha de la celda
  //   final date = details.date;

  //   // Obtener las citas para este día específico
  //   final appointmentsForDay = controller.appointments
  //       .where((app) => _isSameDay(app.startTime, date))
  //       .toList();

  //   // Contar el número de citas para este día
  //   final appointmentCount = appointmentsForDay.length;

  //   // Mostrar el día del mes
  //   return Container(
  //     decoration: BoxDecoration(
  //       color: _isSameDay(date, DateTime.now())
  //           ? Theme.of(context).primaryColor.withOpacity(0.1)
  //           : null,
  //       borderRadius: BorderRadius.circular(4),
  //     ),
  //     child: Stack(
  //       children: [
  //         // Número del día
  //         Padding(
  //           padding: const EdgeInsets.all(4.0),
  //           child: Align(
  //             alignment: Alignment.topCenter,
  //             child: Text(
  //               '${date.day}',
  //               style: TextStyle(
  //                 fontSize: 14,
  //                 fontWeight: _isSameDay(date, DateTime.now())
  //                     ? FontWeight.bold
  //                     : FontWeight.normal,
  //                 color: _isSameDay(date, DateTime.now())
  //                     ? Theme.of(context).primaryColor
  //                     : date.month == details.visibleDates[15].month
  //                         ? Colors.black87
  //                         : Colors.grey[400],
  //               ),
  //             ),
  //           ),
  //         ),

  //         // Mostrar contador de citas si hay al menos una cita
  //         if (appointmentCount > 0)
  //           Positioned(
  //             bottom: 2,
  //             right: 2,
  //             child: Container(
  //               padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
  //               decoration: BoxDecoration(
  //                 color: Theme.of(context).primaryColor.withOpacity(0.8),
  //                 borderRadius: BorderRadius.circular(10),
  //               ),
  //               child: Text(
  //                 appointmentCount.toString(),
  //                 style: const TextStyle(
  //                   color: Colors.white,
  //                   fontSize: 10,
  //                   fontWeight: FontWeight.bold,
  //                 ),
  //               ),
  //             ),
  //           ),
  //       ],
  //     ),
  //   );
  // }

  // Método para construir celdas mensuales personalizadas con contador de citas
  Widget _buildMonthCell(BuildContext context, MonthCellDetails details) {
    // Obtener la fecha de la celda
    final date = details.date;

    // Obtener las citas para este día específico
    final appointmentsForDay = controller.appointments
        .where((app) => _isSameDay(app.startTime, date))
        .toList();

    // Contar el número de citas para este día
    final appointmentCount = appointmentsForDay.length;

    // Verificar si es el día actual
    final isToday = _isSameDay(date, DateTime.now());

    // Verificar si es un día del mes actual o de otro mes
    final isCurrentMonth = date.month == details.visibleDates[15].month;

    // Mostrar el día del mes con diseño mejorado
    return Container(
      decoration: BoxDecoration(
        color: isToday
            ? Theme.of(context).primaryColor.withOpacity(0.15)
            : isCurrentMonth
                ? Colors.white
                : Colors.grey[100],
        borderRadius: BorderRadius.circular(4),
        border: isToday
            ? Border.all(
                color: Theme.of(context).primaryColor,
                width: 1.5,
              )
            : null,
      ),
      child: Stack(
        children: [
          // Número del día
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: isToday
                  ? BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(12),
                    )
                  : null,
              child: Text(
                '${date.day}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isToday || date.day == 1
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: isToday
                      ? Colors.white
                      : !isCurrentMonth
                          ? Colors.grey[400]
                          : Colors.black87,
                ),
              ),
            ),
          ),

          // Mostrar SOLO contador de citas si hay al menos una cita
          if (appointmentCount > 0)
            Positioned(
              bottom: 4,
              right: 0,
              left: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Text(
                    appointmentCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Método auxiliar para comparar si dos fechas son el mismo día
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
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

    // Determinar colores basados en el estado de pago
    final bool isPaid = appointmentEntity.isPaymentCompleted;

    final Color statusColor = isPaid
        ? appointmentEntity.getPaymentStatusColor()
        : appointmentEntity.getStatusColor();

    final Color appointmentBaseColor = isPaid
        ? Color.lerp(appointment.color, Colors.green, 0.15) ?? appointment.color
        : appointment.color;

    // Verificar si estamos en vista semanal para simplificar la visualización
    final bool isWeekView = controller.currentView.value == CalendarView.week ||
        controller.currentView.value == CalendarView.workWeek;

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

    // Vista semanal simplificada para TODAS las citas (tanto múltiples como individuales)
    if (isWeekView) {
      // Determinar si esta es la primera o última subcita
      final bool isFirstSubAppointment =
          subAppointmentIndex == 0 || subAppointmentIndex == -1;
      final bool isLastSubAppointment =
          subAppointmentIndex == totalSubAppointments - 1 ||
              subAppointmentIndex == -1;

      // Color de borde lateral según estado de pago
      final Color borderColor = isPaid ? Colors.green : statusColor;

      // Para vista semanal, mostrar sólo el indicador de color
      return GestureDetector(
        onTap: () => showAppointmentDetails(context, appointmentEntity),
        child: Container(
          constraints: const BoxConstraints(
            minHeight: 32,
          ),
          margin: EdgeInsets.symmetric(
            horizontal: 1, // Reducido de 3 a 1
            vertical: isSubAppointment ? 0 : 1, // Reducido de 3 a 1
          ),
          decoration: BoxDecoration(
            color: appointmentBaseColor,
            borderRadius: isSubAppointment
                ? _getSubAppointmentBorderRadius(
                    subAppointmentIndex, totalSubAppointments)
                : BorderRadius.circular(6), // Reducido de 8 a 6
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isSubAppointment ? 0.05 : 0.1),
                blurRadius: isSubAppointment ? 1 : 2,
                offset: Offset(0, isSubAppointment ? 0.5 : 1),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Línea decorativa lateral para todas las citas
              Positioned(
                top: 0,
                bottom: 0,
                left: 0.3,
                child: Container(
                  width: 4, // Reducido de 5 a 4
                  decoration: BoxDecoration(
                    color: borderColor,
                    borderRadius: BorderRadius.only(
                      topLeft: (isFirstSubAppointment)
                          ? const Radius.circular(6)
                          : Radius.zero,
                      bottomLeft: (isLastSubAppointment)
                          ? const Radius.circular(6)
                          : Radius.zero,
                    ),
                  ),
                ),
              ),

              // // Indicador de estado (solo en la primera subcita o cita individual)
              // if (isFirstSubAppointment)
              //   Positioned(
              //     top: 2,
              //     right: 2,
              //     child: Container(
              //       width: 8, // Reducido de 10 a 8
              //       height: 8, // Reducido de 10 a 8
              //       decoration: BoxDecoration(
              //         color: statusColor,
              //         shape: BoxShape.circle,
              //         border: Border.all(
              //           color: Colors.white,
              //           width: 1,
              //         ),
              //       ),
              //     ),
              //   ),

              // // Indicador de pago (solo en la primera subcita o cita individual)
              // if (isFirstSubAppointment && isPaid)
              //   Positioned(
              //     bottom: 2,
              //     right: 2,
              //     child: Container(
              //       width: 8,
              //       height: 8,
              //       decoration: BoxDecoration(
              //         color: Colors.green,
              //         shape: BoxShape.circle,
              //         border: Border.all(
              //           color: Colors.white,
              //           width: 1,
              //         ),
              //       ),
              //     ),
              //   ),
            ],
          ),
        ),
      );
    }

    // Vista diaria con información completa
    String serviceText = '';
    String clientName = '';

    if (isSubAppointment) {
      // Para subcitas, extraer el servicio específico
      if (subAppointmentIndex >= 0 &&
          subAppointmentIndex < appointmentEntity.serviceTypes.length) {
        serviceText = appointmentEntity.serviceTypes[subAppointmentIndex];
      }
      // Solo mostrar el nombre del cliente en la primera subcita
      clientName = subAppointmentIndex == 0 ? appointmentEntity.clientName : '';
    } else {
      // Para citas normales, usar el subject
      final parts = appointment.subject.split('\n');
      clientName = parts.isNotEmpty ? parts[0] : '';
      serviceText = parts.length > 1 ? parts[1] : '';
    }

    // Determinar si esta es la primera o última subcita
    final bool isFirstSubAppointment =
        subAppointmentIndex == 0 || subAppointmentIndex == -1;
    final bool isLastSubAppointment =
        subAppointmentIndex == totalSubAppointments - 1 ||
            subAppointmentIndex == -1;

    // Obtener el color de borde lateral según estado de pago
    final Color borderColor = isPaid ? Colors.green : statusColor;

    // Diseño para vista diaria con información completa
    return GestureDetector(
      onTap: () => showAppointmentDetails(context, appointmentEntity),
      child: Container(
        constraints: const BoxConstraints(
          minHeight: 32,
        ),
        // Margen vertical cero para citas con múltiples servicios
        margin: EdgeInsets.symmetric(
          horizontal: 3,
          // Para subcitas: sin margen vertical para que queden pegadas
          // Para citas únicas: margen normal
          vertical: isSubAppointment ? 0 : 3,
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
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.1,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (clientName.isNotEmpty) const SizedBox(height: 2),
                        if (clientName.isNotEmpty)
                          Text(
                            clientName,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 10,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),

                  // Para citas múltiples, mostrar indicador de servicio
                  if (totalSubAppointments > 1)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 2),
                      margin: const EdgeInsets.only(left: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        isSubAppointment
                            ? "${subAppointmentIndex + 1}/$totalSubAppointments"
                            : "1/$totalSubAppointments",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Indicador de estado (solo en la primera subcita o cita única)
            if (isFirstSubAppointment)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: statusColor.withOpacity(0.4),
                        blurRadius: 2,
                        spreadRadius: 0.5,
                      ),
                    ],
                  ),
                ),
              ),

            // Línea decorativa lateral para todas las citas (subcitas y citas individuales)
            Positioned(
              top: 0,
              bottom: 0,
              left: 0.3,
              child: Container(
                width: 5,
                decoration: BoxDecoration(
                  color: borderColor,
                  borderRadius: BorderRadius.only(
                    topLeft: (isFirstSubAppointment)
                        ? const Radius.circular(8)
                        : Radius.zero,
                    bottomLeft: (isLastSubAppointment)
                        ? const Radius.circular(8)
                        : Radius.zero,
                  ),
                ),
              ),
            ),

            // Indicador de pago (solo en la primera subcita o cita única)
            if (isFirstSubAppointment && isPaid)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  margin: const EdgeInsets.only(right: 4, bottom: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white,
                      width: 0.5,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 6,
                        color: Colors.white,
                      ),
                      SizedBox(width: 2),
                      Text(
                        "PAGADO",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 6,
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
        bottomLeft: Radius.circular(0),
        bottomRight: Radius.circular(0),
      );
    } else if (index == total - 1) {
      // Última subcita: bordes redondeados abajo
      return const BorderRadius.only(
        topLeft: Radius.circular(0),
        topRight: Radius.circular(0),
        bottomLeft: Radius.circular(8),
        bottomRight: Radius.circular(8),
      );
    } else {
      // Subcitas intermedias: sin bordes redondeados
      return BorderRadius.zero;
    }
  }
}
