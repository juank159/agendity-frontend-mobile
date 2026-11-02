import 'package:flutter/material.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/core/utils/formatters.dart';
import 'package:login_signup/core/widgets/app_gradient_button.dart';
import 'package:login_signup/shared/widgets/app_sheet.dart';

/// Selector de hora de la app (D-23, guía §3): una hoja con tres ruedas
/// (**hora 1–12**, **minutos** con paso configurable y **a. m./p. m.**), una
/// vista previa grande ("9:30 a. m.", `formatTimeOfDay`) y los botones
/// "Cancelar" y "Listo". Devuelve un `TimeOfDay` (24 h por dentro) o `null`.
///
/// Sustituye al `showTimePicker` de Material en toda la app (7.05b lo había
/// forzado a 24 h). Las ruedas llevan `Key` ([hourWheelKey],
/// [minuteWheelKey], [periodWheelKey]) y semántica con subir/bajar, para las
/// pruebas y los lectores de pantalla.
class AppTimePicker extends StatefulWidget {
  static const Key hourWheelKey = Key('time-picker-hour');
  static const Key minuteWheelKey = Key('time-picker-minute');
  static const Key periodWheelKey = Key('time-picker-period');
  static const Key doneKey = Key('time-picker-done');

  /// Horas de la rueda, en orden: 1…12.
  static const List<int> hours = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12];

  final TimeOfDay initial;
  final int minuteStep;
  final String title;

  const AppTimePicker({
    super.key,
    required this.initial,
    this.minuteStep = 5,
    this.title = 'Elige la hora',
  }) : assert(minuteStep > 0 && minuteStep <= 60);

  /// Abre la hoja. [minuteStep]: de cuánto en cuánto van los minutos (5 por
  /// defecto); si [initial] no cae en el paso, su minuto también se ofrece.
  static Future<TimeOfDay?> show(
    BuildContext context, {
    required TimeOfDay initial,
    int minuteStep = 5,
    String title = 'Elige la hora',
  }) =>
      showModalBottomSheet<TimeOfDay>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        builder: (_) => AppTimePicker(
            initial: initial, minuteStep: minuteStep, title: title),
      );

  /// Minutos de la rueda: 0, [step], 2·[step]… y [initialMinute] si no cae
  /// en el paso (ordenados).
  static List<int> minuteValues(int step, int initialMinute) {
    final values = <int>{for (var m = 0; m < 60; m += step) m};
    values.add(initialMinute.clamp(0, 59));
    return values.toList()..sort();
  }

  /// Hora en 12 h de [time] (`0` → 12).
  static int hour12Of(TimeOfDay time) =>
      time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;

  /// Hora 1–12 + minuto + tarde → `TimeOfDay` (24 h).
  static TimeOfDay compose(int hour12, int minute, {required bool pm}) =>
      TimeOfDay(hour: hour12 % 12 + (pm ? 12 : 0), minute: minute);

  @override
  State<AppTimePicker> createState() => _AppTimePickerState();
}

class _AppTimePickerState extends State<AppTimePicker> {
  late final List<int> _minutes;
  late final FixedExtentScrollController _hourScroll;
  late final FixedExtentScrollController _minuteScroll;
  late final FixedExtentScrollController _periodScroll;
  late int _hour12;
  late int _minute;
  late bool _pm;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _minutes = AppTimePicker.minuteValues(widget.minuteStep, initial.minute);
    _hour12 = AppTimePicker.hour12Of(initial);
    _minute = initial.minute;
    _pm = initial.period == DayPeriod.pm;
    _hourScroll = FixedExtentScrollController(
        initialItem: AppTimePicker.hours.indexOf(_hour12));
    _minuteScroll =
        FixedExtentScrollController(initialItem: _minutes.indexOf(_minute));
    _periodScroll = FixedExtentScrollController(initialItem: _pm ? 1 : 0);
  }

  @override
  void dispose() {
    _hourScroll.dispose();
    _minuteScroll.dispose();
    _periodScroll.dispose();
    super.dispose();
  }

  TimeOfDay get _value => AppTimePicker.compose(_hour12, _minute, pm: _pm);

  static int _wrap(int index, int length) => index % length;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final preview = formatTimeOfDay(_value);
    return AppSheet(
      title: widget.title,
      icon: Icons.schedule_rounded,
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        AppGradientButton(
          key: AppTimePicker.doneKey,
          label: 'Listo',
          icon: Icons.check_rounded,
          onPressed: () => Navigator.of(context).pop(_value),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              liveRegion: true,
              label: 'Hora elegida',
              value: preview,
              excludeSemantics: true,
              child: Text(
                preview,
                key: const Key('time-picker-preview'),
                style: theme.textTheme.displaySmall?.tabular.copyWith(
                  fontWeight: FontWeight.w800,
                  color: scheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 220,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Banda de la selección.
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer.withValues(alpha: 0.55),
                      borderRadius: AppRadii.fieldRadius,
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _Wheel(
                          key: AppTimePicker.hourWheelKey,
                          semanticLabel: 'Hora',
                          controller: _hourScroll,
                          labels: [
                            for (final h in AppTimePicker.hours) '$h',
                          ],
                          selected: AppTimePicker.hours.indexOf(_hour12),
                          looping: true,
                          onChanged: (i) => setState(() => _hour12 =
                              AppTimePicker
                                  .hours[_wrap(i, AppTimePicker.hours.length)]),
                        ),
                      ),
                      Text(':',
                          style: theme.textTheme.headlineMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                              fontWeight: FontWeight.w700)),
                      Expanded(
                        child: _Wheel(
                          key: AppTimePicker.minuteWheelKey,
                          semanticLabel: 'Minutos',
                          controller: _minuteScroll,
                          labels: [
                            for (final m in _minutes)
                              m.toString().padLeft(2, '0'),
                          ],
                          selected: _minutes.indexOf(_minute),
                          looping: true,
                          onChanged: (i) => setState(() =>
                              _minute = _minutes[_wrap(i, _minutes.length)]),
                        ),
                      ),
                      Expanded(
                        child: _Wheel(
                          key: AppTimePicker.periodWheelKey,
                          semanticLabel: 'Mañana o tarde',
                          controller: _periodScroll,
                          labels: const [timeAmLabel, timePmLabel],
                          selected: _pm ? 1 : 0,
                          onChanged: (i) => setState(() => _pm = i == 1),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Una rueda con sus textos; semántica de valor con subir/bajar.
class _Wheel extends StatelessWidget {
  final String semanticLabel;
  final FixedExtentScrollController controller;
  final List<String> labels;
  final int selected;
  final bool looping;
  final ValueChanged<int> onChanged;

  const _Wheel({
    super.key,
    required this.semanticLabel,
    required this.controller,
    required this.labels,
    required this.selected,
    required this.onChanged,
    this.looping = false,
  });

  void _step(int delta) {
    final target = controller.selectedItem + delta;
    if (!looping && (target < 0 || target >= labels.length)) return;
    controller.jumpToItem(target);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    Widget item(int index) {
      final isSelected = index == selected;
      return Center(
        child: Text(
          labels[index],
          style: theme.textTheme.titleLarge?.tabular.copyWith(
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
            color: isSelected ? scheme.onSurface : scheme.onSurfaceVariant,
          ),
        ),
      );
    }

    final canIncrease = looping || selected + 1 < labels.length;
    final canDecrease = looping || selected > 0;
    return Semantics(
      label: semanticLabel,
      value: labels[selected],
      increasedValue:
          canIncrease ? labels[(selected + 1) % labels.length] : null,
      decreasedValue:
          canDecrease ? labels[(selected - 1) % labels.length] : null,
      onIncrease: canIncrease ? () => _step(1) : null,
      onDecrease: canDecrease ? () => _step(-1) : null,
      child: ListWheelScrollView.useDelegate(
        controller: controller,
        itemExtent: 48,
        diameterRatio: 1.5,
        perspective: 0.004,
        overAndUnderCenterOpacity: 0.5,
        physics: const FixedExtentScrollPhysics(),
        onSelectedItemChanged: onChanged,
        childDelegate: looping
            ? ListWheelChildLoopingListDelegate(
                children: [for (var i = 0; i < labels.length; i++) item(i)])
            : ListWheelChildBuilderDelegate(
                childCount: labels.length,
                builder: (context, index) => item(index),
              ),
      ),
    );
  }
}
