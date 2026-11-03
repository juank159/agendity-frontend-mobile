import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/core/utils/business_time_zone.dart';
import 'package:login_signup/core/utils/formatters.dart';
import 'package:login_signup/features/appointments/presentation/controllers/appointments_controller.dart';
import 'package:login_signup/features/appointments/presentation/widgets/agenda_toolbar.dart';
import 'package:login_signup/features/appointments/presentation/widgets/appointment_calendar_data_source.dart';
import 'package:login_signup/features/appointments/presentation/widgets/appointment_detail_dialog.dart';
import 'package:login_signup/features/appointments/presentation/widgets/appointment_form_dialog.dart';
import 'package:login_signup/features/appointments/presentation/widgets/appointment_tile.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

/// Calendario de la agenda (día, semana o mes) con el estilo de la guía
/// (12.04): barra propia (`AgendaToolbar`), líneas suaves, hoy resaltado y
/// una tarjeta "3D" por cita (`AppointmentTile`).
///
/// - Mes o semana: tocar un día abre su vista de día (en el mes, cada día
///   muestra cuántas citas tiene).
/// - Día: tocar una hora libre abre el formulario de cita nueva con esa hora
///   (Owner y Employee) y la celda se resalta; tocar una cita abre su detalle.
class AppointmentCalendar extends GetView<AppointmentsController> {
  const AppointmentCalendar({super.key});

  /// Ancho de la columna de horas (la franja de días de la semana se alinea
  /// con él).
  static const double timeRulerSize = 70;

  /// Primera hora visible del día [selected]: si es hoy (en la zona del
  /// negocio, D-15), una hora antes de "ahora", para que la tarde no quede
  /// fuera de la vista al abrir la agenda; si no, el inicio de la vista.
  @visibleForTesting
  static DateTime initialDisplayDateFor(DateTime selected) {
    final now = BusinessTimeZone.now();
    final isToday = selected.year == now.year &&
        selected.month == now.month &&
        selected.day == now.day;
    if (!isToday) return selected;
    final hour = (now.hour - 1).clamp(startHour, 23);
    return DateTime(selected.year, selected.month, selected.day, hour);
  }

  /// Primera hora de la vista de día y de semana.
  static const int startHour = 6;

  void _onTap(CalendarTapDetails details) {
    final date = details.date;
    switch (details.targetElement) {
      case CalendarElement.appointment:
        final blocks = details.appointments;
        if (blocks == null || blocks.isEmpty) return;
        final block = blocks.first;
        if (block is! Appointment) return;
        final appointment = controller.byId('${block.id}');
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
    final tokens = context.tokens;
    final muted = theme.textTheme.labelSmall
        ?.copyWith(
            color: scheme.onSurfaceVariant,
            fontSize: 11,
            fontWeight: FontWeight.w600)
        .tabular;
    final softLine = scheme.outlineVariant.withValues(alpha: 0.45);

    return Column(
      children: [
        const AgendaToolbar(timeRulerSize: timeRulerSize),
        Expanded(
          child: Obx(() {
            final view = controller.currentView.value;
            final isWeek =
                view == CalendarView.week || view == CalendarView.workWeek;
            final isMonth = view == CalendarView.month;
            return Stack(
              children: [
                SfCalendar(
                  key: ValueKey('calendar-${controller.navigation.value}'),
                  view: view,
                  initialDisplayDate:
                      initialDisplayDateFor(controller.selectedDate.value),
                  dataSource: AppointmentCalendarDataSource(
                      controller.visibleAppointments),
                  onViewChanged: (details) =>
                      Future.microtask(() => controller.onViewChanged(details)),
                  onTap: _onTap,
                  firstDayOfWeek: 1,
                  // La barra y la franja de días son de `AgendaToolbar`.
                  headerHeight: 0,
                  viewHeaderHeight: isMonth ? 30 : 0,
                  // La línea de "ahora" del calendario usa el reloj del
                  // dispositivo: se oculta si el negocio está en otra zona
                  // (D-15).
                  showCurrentTimeIndicator: !BusinessTimeZone.differsFromDevice,
                  backgroundColor: scheme.surface,
                  todayHighlightColor: scheme.primary,
                  cellBorderColor: softLine,
                  viewHeaderStyle: ViewHeaderStyle(
                    backgroundColor: scheme.surface,
                    dayTextStyle: muted,
                  ),
                  // Hora libre tocada: un toque suave de la paleta.
                  selectionDecoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.10),
                    border: Border.all(
                        color: scheme.primary.withValues(alpha: 0.55),
                        width: 1.5),
                    borderRadius: AppRadii.chipRadius,
                  ),
                  timeSlotViewSettings: TimeSlotViewSettings(
                    startHour: startHour.toDouble(),
                    endHour: 24,
                    timeFormat: 'h:mm a',
                    timeInterval: const Duration(minutes: 30),
                    timeIntervalHeight: 70,
                    timeRulerSize: timeRulerSize,
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
                    final appointment = controller.byId('${block.id}');
                    if (appointment == null) return const SizedBox.shrink();
                    return AppointmentTile(
                      key: ValueKey('tile-${appointment.id}'),
                      appointment: appointment,
                      compact: isWeek,
                    );
                  },
                  monthCellBuilder: (context, details) => _MonthCell(
                    date: details.date,
                    isCurrentMonth: details.date.month ==
                        details.visibleDates[details.visibleDates.length ~/ 2]
                            .month,
                    count: controller.countOn(details.date),
                  ),
                ),
                if (controller.isLoading.value)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: LinearProgressIndicator(
                      minHeight: 3,
                      color: tokens.gradientEnd,
                      backgroundColor: scheme.surface.withValues(alpha: 0),
                    ),
                  ),
              ],
            );
          }),
        ),
      ],
    );
  }
}

/// Día de la vista de mes: el número (hoy, en píldora con el degradado) y
/// el contador de citas en una píldora.
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = context.tokens;
    final today = BusinessTimeZone.today();
    final isToday = date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;
    final dayColor = isToday
        ? tokens.onGradient
        : isCurrentMonth
            ? scheme.onSurface
            : scheme.outline;

    return Semantics(
      label: count == 0 ? null : formatCount(count, 'cita', 'citas'),
      child: Container(
        margin: const EdgeInsets.all(1.5),
        decoration: BoxDecoration(
          color: isCurrentMonth
              ? (isToday
                  ? scheme.primaryContainer.withValues(alpha: 0.35)
                  : scheme.surfaceContainerLow)
              : scheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: isToday
                  ? scheme.primary.withValues(alpha: 0.5)
                  : scheme.outlineVariant.withValues(alpha: 0.35)),
        ),
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: isToday
                    ? BoxDecoration(
                        gradient: tokens.primaryGradient,
                        borderRadius: AppRadii.chipRadius,
                      )
                    : null,
                child: Text('${date.day}',
                    style: theme.textTheme.labelLarge
                        ?.copyWith(
                          color: dayColor,
                          fontWeight:
                              isToday ? FontWeight.w800 : FontWeight.w600,
                        )
                        .tabular),
              ),
            ),
            if (count > 0)
              Positioned(
                bottom: 4,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    key: ValueKey(
                        'month-count-${date.year}-${date.month}-${date.day}'),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color:
                          isCurrentMonth ? null : scheme.surfaceContainerHigh,
                      gradient: isCurrentMonth
                          ? tokens.gradientOf(scheme.primary)
                          : null,
                      borderRadius: AppRadii.chipRadius,
                      border: Border.all(color: tokens.innerBorder),
                    ),
                    child: Text('$count',
                        style: theme.textTheme.labelSmall
                            ?.copyWith(
                              color: isCurrentMonth
                                  ? scheme.onPrimary
                                  : scheme.onSurfaceVariant,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                            )
                            .tabular),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
