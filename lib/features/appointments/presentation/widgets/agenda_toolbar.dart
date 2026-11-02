import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/core/utils/business_time_zone.dart';
import 'package:login_signup/features/appointments/presentation/controllers/appointments_controller.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

/// Barra de la agenda (12.04) encima del calendario: flechas, el periodo
/// visible (tocarlo abre el selector de fecha), "Hoy", el selector de vista
/// (día, semana, mes) y, en día y semana, la franja de días en píldoras.
///
/// Sustituye a la cabecera y al encabezado de días de Syncfusion, que no se
/// pueden estilizar como pide la guía. Toda la navegación pasa por
/// `AppointmentsController` (`step`, `goToToday`, `changeView`, `showDay`).
class AgendaToolbar extends GetView<AppointmentsController> {
  /// Ancho de la columna de horas del calendario (la franja de la semana se
  /// alinea con sus columnas).
  final double timeRulerSize;

  const AgendaToolbar({super.key, required this.timeRulerSize});

  static String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  /// Texto del periodo visible: "Noviembre" o "2 – 8 nov"; con el año
  /// ("Enero 2027", "28 dic – 3 ene 2027") si no es el de [today].
  static String periodLabel(CalendarView view, DateTime date,
      {required DateTime today}) {
    String short(DateTime d) =>
        DateFormat('d MMM', 'es').format(d).replaceAll('.', '');
    if (view == CalendarView.week || view == CalendarView.workWeek) {
      final range = AppointmentsController.rangeFor(view, date);
      final first = range.start;
      final last = range.end.subtract(const Duration(days: 1));
      final from = first.month == last.month ? '${first.day}' : short(first);
      final year = first.year == today.year && last.year == today.year
          ? ''
          : ' ${last.year}';
      return '$from – ${short(last)}$year';
    }
    final month = _capitalize(DateFormat('MMMM', 'es').format(date));
    return date.year == today.year ? month : '$month ${date.year}';
  }

  Future<void> _pickDate(BuildContext context) async {
    final current = controller.selectedDate.value;
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(current.year - 5),
      lastDate: DateTime(current.year + 5, 12, 31),
      currentDate: BusinessTimeZone.today(),
      helpText: 'Ir a la fecha',
    );
    if (picked != null) {
      await controller.changeView(controller.currentView.value,
          targetDate: picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Obx(() {
      final view = controller.currentView.value;
      final date = controller.selectedDate.value;
      final isMonth = view == CalendarView.month;
      return Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  _RoundIconButton(
                    key: const Key('agenda-previous'),
                    icon: Icons.chevron_left_rounded,
                    tooltip: 'Anterior',
                    onPressed: () => controller.step(-1),
                  ),
                  Expanded(
                    child: InkWell(
                      key: const Key('agenda-period'),
                      borderRadius: AppRadii.chipRadius,
                      onTap: () => _pickDate(context),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                periodLabel(view, date,
                                    today: BusinessTimeZone.today()),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                            ),
                            Icon(Icons.expand_more_rounded,
                                size: 18, color: scheme.onSurfaceVariant),
                          ],
                        ),
                      ),
                    ),
                  ),
                  _RoundIconButton(
                    key: const Key('agenda-next'),
                    icon: Icons.chevron_right_rounded,
                    tooltip: 'Siguiente',
                    onPressed: () => controller.step(1),
                  ),
                  if (!controller.showsToday)
                    _RoundIconButton(
                      key: const Key('agenda-today'),
                      icon: Icons.today_rounded,
                      tooltip: 'Ir a hoy',
                      onPressed: controller.goToToday,
                    ),
                  const SizedBox(width: 4),
                  _ViewSwitch(
                    current: view,
                    onSelected: (v) {
                      if (v != view) controller.changeView(v);
                    },
                  ),
                ],
              ),
            ),
            if (!isMonth) ...[
              const SizedBox(height: 6),
              Padding(
                padding: EdgeInsets.only(
                    left: view == CalendarView.day ? 10 : timeRulerSize,
                    right: view == CalendarView.day ? 10 : 0),
                child: _DayStrip(
                  view: view,
                  selected: date,
                  onTap: controller.showDay,
                ),
              ),
            ],
          ],
        ),
      );
    });
  }
}

/// Flecha redonda tonal.
class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _RoundIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: IconButton.filledTonal(
          icon: Icon(icon, size: 20),
          tooltip: tooltip,
          constraints: const BoxConstraints.tightFor(width: 34, height: 34),
          padding: EdgeInsets.zero,
          onPressed: onPressed,
        ),
      );
}

/// Selector de vista en píldora: la elegida lleva el degradado de la paleta.
class _ViewSwitch extends StatelessWidget {
  final CalendarView current;
  final ValueChanged<CalendarView> onSelected;

  const _ViewSwitch({required this.current, required this.onSelected});

  static const _options = [
    (CalendarView.day, 'Día', 'agenda-view-day'),
    (CalendarView.week, 'Semana', 'agenda-view-week'),
    (CalendarView.month, 'Mes', 'agenda-view-month'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = context.tokens;
    final selectedView =
        current == CalendarView.workWeek ? CalendarView.week : current;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: AppRadii.fieldRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (view, label, key) in _options)
            Semantics(
              selected: view == selectedView,
              button: true,
              child: AnimatedContainer(
                duration: AppMotion.of(context),
                curve: AppMotion.curve,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadii.field - 3),
                  gradient:
                      view == selectedView ? tokens.primaryGradient : null,
                  boxShadow: view == selectedView
                      ? tokens.elevation1(tint: tokens.gradientEnd)
                      : null,
                ),
                child: InkWell(
                  key: Key(key),
                  borderRadius: BorderRadius.circular(AppRadii.field - 3),
                  onTap: () => onSelected(view),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Text(
                      label,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: view == selectedView
                            ? tokens.onGradient
                            : scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Los 7 días de la semana visible en píldoras: hoy con el color primario y,
/// en la vista de día, el elegido con el degradado. Tocar uno abre ese día.
class _DayStrip extends StatelessWidget {
  final CalendarView view;
  final DateTime selected;
  final ValueChanged<DateTime> onTap;

  const _DayStrip({
    required this.view,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = context.tokens;
    final monday =
        AppointmentsController.rangeFor(CalendarView.week, selected).start;
    final today = BusinessTimeZone.today();
    final isDay = view == CalendarView.day;
    bool same(DateTime a, DateTime b) =>
        a.year == b.year && a.month == b.month && a.day == b.day;

    return Row(
      children: [
        for (var i = 0; i < 7; i++)
          Expanded(
            child: Builder(builder: (context) {
              final day = DateTime(monday.year, monday.month, monday.day + i);
              final isToday = same(day, today);
              final isSelected = isDay && same(day, selected);
              final filled = isSelected || (!isDay && isToday);
              final foreground = filled
                  ? tokens.onGradient
                  : isToday
                      ? scheme.primary
                      : scheme.onSurface;
              final weekday = DateFormat('EEE', 'es')
                  .format(day)
                  .replaceAll('.', '')
                  .toUpperCase();
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1.5),
                child: Semantics(
                  selected: isSelected,
                  button: true,
                  label: DateFormat("EEEE d 'de' MMMM", 'es').format(day),
                  excludeSemantics: true,
                  child: AnimatedContainer(
                    duration: AppMotion.of(context),
                    curve: AppMotion.curve,
                    decoration: BoxDecoration(
                      borderRadius: AppRadii.chipRadius,
                      gradient: filled ? tokens.primaryGradient : null,
                      color: filled
                          ? null
                          : isToday
                              ? scheme.primaryContainer.withValues(alpha: 0.6)
                              : null,
                      border: isToday && !filled
                          ? Border.all(color: scheme.primary, width: 1.2)
                          : null,
                      boxShadow: filled
                          ? tokens.elevation1(tint: tokens.gradientEnd)
                          : null,
                    ),
                    child: InkWell(
                      key:
                          Key('agenda-day-${day.year}-${day.month}-${day.day}'),
                      borderRadius: AppRadii.chipRadius,
                      onTap: () => onTap(day),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              weekday,
                              maxLines: 1,
                              overflow: TextOverflow.clip,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: filled
                                    ? foreground.withValues(alpha: 0.85)
                                    : scheme.onSurfaceVariant,
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
                              ),
                            ),
                            Text(
                              '${day.day}',
                              style: theme.textTheme.titleSmall
                                  ?.copyWith(
                                    color: foreground,
                                    fontWeight: FontWeight.w800,
                                  )
                                  .tabular,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
      ],
    );
  }
}
