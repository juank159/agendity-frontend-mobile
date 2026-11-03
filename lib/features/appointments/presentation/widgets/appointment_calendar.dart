import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/core/utils/business_time_zone.dart';
import 'package:login_signup/core/utils/formatters.dart';
import 'package:login_signup/features/appointments/domain/usecases/agenda_hours.dart';
import 'package:login_signup/features/appointments/presentation/controllers/appointments_controller.dart';
import 'package:login_signup/features/appointments/presentation/widgets/agenda_cell_tap.dart';
import 'package:login_signup/features/appointments/presentation/widgets/agenda_day_notice.dart';
import 'package:login_signup/features/appointments/presentation/widgets/agenda_toolbar.dart';
import 'package:login_signup/features/appointments/presentation/widgets/appointment_calendar_data_source.dart';
import 'package:login_signup/features/appointments/presentation/widgets/appointment_detail_dialog.dart';
import 'package:login_signup/features/appointments/presentation/widgets/appointment_tile.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

/// Calendario de la agenda (día, semana o mes) con el estilo de la guía
/// (12.04): barra propia (`AgendaToolbar`), líneas suaves, hoy resaltado y
/// una tarjeta "3D" por cita (`AppointmentTile`).
///
/// Horario (D-25, `AgendaHours`): la vista de día va de la hora de apertura
/// a la de cierre de ese día (se amplía si hay citas fuera) y la de semana,
/// la unión de sus días; lo que no se puede reservar va sombreado con
/// "Cerrado"; un día cerrado lleva un aviso arriba y en el mes se ve
/// atenuado.
///
/// - Mes o semana: tocar un día abre su vista de día (en el mes, cada día
///   muestra cuántas citas tiene).
/// - Día: tocar una hora reservable abre "Nueva cita" con esa hora y un
///   profesional libre; fuera de horario, lo explica (`openAgendaCell`).
///   Tocar una cita abre su detalle.
class AppointmentCalendar extends GetView<AppointmentsController> {
  const AppointmentCalendar({super.key});

  /// Ancho de la columna de horas (la franja de días de la semana se alinea
  /// con él).
  static const double timeRulerSize = 70;

  /// Primera hora visible del día [selected] (entre [startHour] y
  /// [endHour], el rango de ese día): si es hoy (en la zona del negocio,
  /// D-15), una hora antes de "ahora", para que la tarde no quede fuera de
  /// la vista al abrir la agenda; si no, el inicio de la vista.
  @visibleForTesting
  static DateTime initialDisplayDateFor(DateTime selected,
      {int startHour = AppointmentCalendar.startHour, int endHour = 24}) {
    final now = BusinessTimeZone.now();
    final isToday = selected.year == now.year &&
        selected.month == now.month &&
        selected.day == now.day;
    if (!isToday) return selected;
    final last = endHour - 1 < startHour ? startHour : endHour - 1;
    final hour = (now.hour - 1).clamp(startHour, last);
    return DateTime(selected.year, selected.month, selected.day, hour);
  }

  /// Primera hora de la vista de día y de semana sin horario configurado.
  static const int startHour = AgendaHours.defaultStartHour;

  /// Una franja no reservable de la agenda (para pruebas y capturas).
  static const closedRegionText = 'Cerrado';

  void _onTap(BuildContext context, CalendarTapDetails details,
      CalendarController calendar) {
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
          // Una hora que no se puede reservar no queda resaltada.
          final day = controller.dayHours(date);
          if (!day.isOpenAt(date.hour * 60 + date.minute)) {
            calendar.selectedDate = null;
          }
          openAgendaCell(context, controller, date);
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
        const AgendaDayNotice(),
        Expanded(
          child: Obx(() {
            final view = controller.currentView.value;
            final isWeek =
                view == CalendarView.week || view == CalendarView.workWeek;
            final isMonth = view == CalendarView.month;
            final selected = controller.selectedDate.value;
            final visible = controller.visibleAppointments;

            // Rango de horas y zonas no reservables (D-25).
            var first = AgendaHours.defaultStartHour;
            var last = AgendaHours.defaultEndHour;
            final regions = <TimeRegion>[];
            void shade(DateTime day, List<MinuteSpan> spans) {
              for (final span in spans) {
                regions.add(TimeRegion(
                  startTime:
                      DateTime(day.year, day.month, day.day, 0, span.start),
                  endTime: DateTime(day.year, day.month, day.day, 0, span.end),
                  // Con `false` el calendario se traga el toque y no se
                  // podría explicar por qué esa hora no se reserva: el
                  // toque lo filtra `openAgendaCell` (y la celda no queda
                  // resaltada).
                  enablePointerInteraction: true,
                  text: closedRegionText,
                ));
              }
            }

            if (isWeek) {
              final week = controller.weekHours();
              first = week.startHour;
              last = week.endHour;
              for (final day in week.days) {
                shade(day.day, week.closedOf(day));
              }
            } else if (!isMonth) {
              final day = controller.dayHours(selected);
              first = day.startHour;
              last = day.endHour;
              shade(day.day, day.closed);
            }
            final hours = controller.hours.value;

            return Stack(
              children: [
                _CalendarHost(
                  // Se vuelve a montar al cambiar de vista o fecha desde la
                  // app y cuando cambia el rango de horas (el calendario
                  // conserva el desplazamiento en píxeles, no la hora).
                  key: ValueKey('calendar-${controller.navigation.value}'
                      '-$first-$last'),
                  builder: (calendar) => SfCalendar(
                    controller: calendar,
                    view: view,
                    initialDisplayDate: initialDisplayDateFor(selected,
                        startHour: first, endHour: last),
                    dataSource: AppointmentCalendarDataSource(visible),
                    onViewChanged: (details) => Future.microtask(
                        () => controller.onViewChanged(details)),
                    onTap: (details) => _onTap(context, details, calendar),
                    firstDayOfWeek: 1,
                    // La barra y la franja de días son de `AgendaToolbar`.
                    headerHeight: 0,
                    viewHeaderHeight: isMonth ? 30 : 0,
                    // La línea de "ahora" del calendario usa el reloj del
                    // dispositivo: se oculta si el negocio está en otra
                    // zona (D-15).
                    showCurrentTimeIndicator:
                        !BusinessTimeZone.differsFromDevice,
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
                    specialRegions: regions,
                    timeRegionBuilder: (context, details) => _ClosedRegion(
                        height: details.bounds.height,
                        width: details.bounds.width),
                    timeSlotViewSettings: TimeSlotViewSettings(
                      startHour: first.toDouble(),
                      endHour: last.toDouble(),
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
                      if (block is! Appointment) {
                        return const SizedBox.shrink();
                      }
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
                      closed: hours.day(details.date).open.isEmpty,
                    ),
                  ),
                ),
                if (controller.isLoading.value || controller.isFinding.value)
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

/// Dueño del `CalendarController` de un calendario montado: se crea con él
/// y se libera al desmontarlo (cada navegación de la app monta uno nuevo).
class _CalendarHost extends StatefulWidget {
  final Widget Function(CalendarController calendar) builder;

  const _CalendarHost({super.key, required this.builder});

  @override
  State<_CalendarHost> createState() => _CalendarHostState();
}

class _CalendarHostState extends State<_CalendarHost> {
  final _calendar = CalendarController();

  @override
  void dispose() {
    _calendar.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(_calendar);
}

/// Franja no reservable (fuera de horario o día cerrado): sombreada con un
/// tono suave del tema y "Cerrado" si cabe. No se puede tocar para reservar.
class _ClosedRegion extends StatelessWidget {
  final double height;
  final double width;

  const _ClosedRegion({required this.height, required this.width});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      label: 'Cerrado: no se puede reservar',
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.65),
          border: Border(
            left: BorderSide(
                color: scheme.outlineVariant.withValues(alpha: 0.8), width: 3),
          ),
        ),
        alignment: Alignment.topCenter,
        padding: const EdgeInsets.only(top: 6),
        child: height < 24
            ? null
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_clock_rounded,
                      size: 14, color: scheme.onSurfaceVariant),
                  // En la semana (columnas estrechas) basta el candado.
                  if (width >= 90) ...[
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        AppointmentCalendar.closedRegionText,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

/// Día de la vista de mes: el número (hoy, en píldora con el degradado) y
/// el contador de citas en una píldora.
class _MonthCell extends StatelessWidget {
  final DateTime date;
  final bool isCurrentMonth;
  final int count;

  /// Día cerrado (D-25): se ve atenuado.
  final bool closed;

  const _MonthCell({
    required this.date,
    required this.isCurrentMonth,
    required this.count,
    this.closed = false,
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

    final label = [
      if (closed) 'Cerrado',
      if (count > 0) formatCount(count, 'cita', 'citas'),
    ].join(', ');
    return Semantics(
      label: label.isEmpty ? null : label,
      child: Opacity(
        key: closed
            ? ValueKey('month-closed-${date.year}-${date.month}-${date.day}')
            : null,
        opacity: closed ? 0.45 : 1,
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
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
      ),
    );
  }
}
