import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/utils/business_time_zone.dart';
import 'package:login_signup/core/utils/formatters.dart';
import 'package:login_signup/features/appointments/presentation/controllers/appointments_controller.dart';
import 'package:login_signup/features/appointments/presentation/widgets/appointment_calendar_data_source.dart';
import 'package:login_signup/features/appointments/presentation/widgets/appointment_detail_dialog.dart';
import 'package:login_signup/features/appointments/presentation/widgets/appointment_form_dialog.dart';
import 'package:login_signup/features/appointments/presentation/widgets/appointment_tile.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

/// Calendario de la agenda (día, semana o mes) con los colores del tema.
///
/// - Mes o semana: tocar un día abre su vista de día (en el mes, cada día
///   muestra cuántas citas tiene).
/// - Día: tocar una hora abre el formulario de cita nueva con esa hora
///   (Owner y Employee); tocar una cita abre su detalle.
class AppointmentCalendar extends GetView<AppointmentsController> {
  const AppointmentCalendar({super.key});

  void _onTap(CalendarTapDetails details) {
    final date = details.date;
    switch (details.targetElement) {
      case CalendarElement.appointment:
        final blocks = details.appointments;
        if (blocks == null || blocks.isEmpty) return;
        final block = blocks.first;
        if (block is! Appointment) return;
        final id = AppointmentCalendarDataSource.blockOf(block.id).appointmentId;
        final appointment = controller.byId(id);
        if (appointment != null) AppointmentDetailsDialog.show(appointment);
      case CalendarElement.calendarCell:
        if (date == null) return;
        if (controller.currentView.value == CalendarView.day) {
          startNewAppointment(controller, at: date);
        } else {
          controller.showDay(date);
        }
      default:
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = TextStyle(color: scheme.onSurfaceVariant, fontSize: 12);

    return Obx(() {
      final view = controller.currentView.value;
      final isWeek = view == CalendarView.week || view == CalendarView.workWeek;
      return Stack(
        children: [
          SfCalendar(
            key: ValueKey('calendar-${controller.navigation.value}'),
            view: view,
            initialDisplayDate: controller.selectedDate.value,
            dataSource:
                AppointmentCalendarDataSource(controller.visibleAppointments),
            onViewChanged: (details) =>
                Future.microtask(() => controller.onViewChanged(details)),
            onTap: _onTap,
            firstDayOfWeek: 1,
            headerHeight: 50,
            viewHeaderHeight: 60,
            showNavigationArrow: true,
            showDatePickerButton: true,
            // La línea de "ahora" del calendario usa el reloj del
            // dispositivo: se oculta si el negocio está en otra zona (D-15).
            showCurrentTimeIndicator: !BusinessTimeZone.differsFromDevice,
            backgroundColor: scheme.surface,
            todayHighlightColor: scheme.primary,
            cellBorderColor: scheme.outlineVariant,
            headerStyle: CalendarHeaderStyle(
              textAlign: TextAlign.center,
              backgroundColor: scheme.surface,
              textStyle: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            viewHeaderStyle: ViewHeaderStyle(
              backgroundColor: scheme.surfaceContainerHighest,
              dayTextStyle: muted,
              dateTextStyle: TextStyle(
                  color: scheme.onSurface, fontWeight: FontWeight.bold),
            ),
            selectionDecoration: BoxDecoration(
              border: Border.all(color: scheme.primary, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            timeSlotViewSettings: TimeSlotViewSettings(
              startHour: 6,
              endHour: 24,
              timeFormat: 'h:mm a',
              timeInterval: const Duration(minutes: 30),
              timeIntervalHeight: 70,
              timeRulerSize: 70,
              timeTextStyle: muted,
              dayFormat: 'EEE',
              dateFormat: 'd',
            ),
            monthViewSettings: const MonthViewSettings(
              appointmentDisplayMode: MonthAppointmentDisplayMode.none,
              showTrailingAndLeadingDates: true,
              numberOfWeeksInView: 6,
              dayFormat: 'EEE',
            ),
            appointmentBuilder: (context, details) {
              final block = details.appointments.first;
              if (block is! Appointment) return const SizedBox.shrink();
              final ref = AppointmentCalendarDataSource.blockOf(block.id);
              final appointment = controller.byId(ref.appointmentId);
              if (appointment == null) return const SizedBox.shrink();
              return AppointmentTile(
                appointment: appointment,
                serviceIndex: ref.serviceIndex,
                compact: isWeek,
              );
            },
            monthCellBuilder: (context, details) => _MonthCell(
              date: details.date,
              isCurrentMonth: details.date.month ==
                  details.visibleDates[details.visibleDates.length ~/ 2].month,
              count: controller.countOn(details.date),
            ),
          ),
          if (controller.isLoading.value)
            const Positioned(
                top: 0, left: 0, right: 0, child: LinearProgressIndicator()),
        ],
      );
    });
  }
}

/// Día de la vista de mes con el número de citas.
class _MonthCell extends StatelessWidget {
  final DateTime date;
  final bool isCurrentMonth;
  final int count;

  const _MonthCell({
    required this.date,
    required this.isCurrentMonth,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final today = BusinessTimeZone.today();
    final isToday = date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;
    final dayColor = isToday
        ? scheme.onPrimary
        : isCurrentMonth
            ? scheme.onSurface
            : scheme.outline;

    return Semantics(
      label: count == 0 ? null : formatCount(count, 'cita', 'citas'),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: scheme.outlineVariant, width: 0.5),
        ),
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: isToday
                    ? BoxDecoration(
                        color: scheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      )
                    : null,
                child: Text('${date.day}',
                    style: TextStyle(
                        color: dayColor,
                        fontWeight:
                            isToday ? FontWeight.bold : FontWeight.normal)),
              ),
            ),
            if (count > 0)
              Positioned(
                bottom: 4,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('$count',
                        style: TextStyle(
                            color: scheme.onPrimaryContainer,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
