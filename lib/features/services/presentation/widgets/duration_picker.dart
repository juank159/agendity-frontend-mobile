import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/utils/formatters.dart';

/// Rueda de duraciones (de 15 en 15 minutos, hasta 6 horas). Devuelve la
/// duración elegida o `null` si se cancela.
class DurationPicker extends StatefulWidget {
  static const stepMinutes = 15;
  static const steps = 24;

  final Duration initial;

  const DurationPicker({super.key, required this.initial});

  static Future<Duration?> show(Duration initial) =>
      Get.dialog<Duration>(DurationPicker(initial: initial));

  @override
  State<DurationPicker> createState() => _DurationPickerState();
}

class _DurationPickerState extends State<DurationPicker> {
  late int _index;
  late final FixedExtentScrollController _scroll;

  @override
  void initState() {
    super.initState();
    _index = ((widget.initial.inMinutes / DurationPicker.stepMinutes).round() -
            1)
        .clamp(0, DurationPicker.steps - 1);
    _scroll = FixedExtentScrollController(initialItem: _index);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  int _minutesAt(int index) => (index + 1) * DurationPicker.stepMinutes;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return AlertDialog(
      title: const Text('Duración'),
      content: SizedBox(
        height: 250,
        width: 280,
        child: ListWheelScrollView.useDelegate(
          controller: _scroll,
          itemExtent: 50,
          perspective: 0.006,
          diameterRatio: 1.6,
          physics: const FixedExtentScrollPhysics(),
          onSelectedItemChanged: (index) => setState(() => _index = index),
          childDelegate: ListWheelChildBuilderDelegate(
            childCount: DurationPicker.steps,
            builder: (context, index) {
              final selected = index == _index;
              return Container(
                alignment: Alignment.center,
                color: selected ? scheme.surfaceContainerHighest : null,
                child: Text(
                  formatDurationMinutes(_minutesAt(index)),
                  style: (selected ? text.titleLarge : text.bodyLarge)
                      ?.copyWith(
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                    color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
                  ),
                ),
              );
            },
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context)
              .pop(Duration(minutes: _minutesAt(_index))),
          child: const Text('Aceptar'),
        ),
      ],
    );
  }
}
