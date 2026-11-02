import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/core/utils/formatters.dart';

/// Rueda de duraciones (de 5 en 5 minutos, hasta 6 horas; 7.04-4). Devuelve la
/// duración elegida o `null` si se cancela.
///
/// La fila elegida va en negrita sobre una banda tonal (el `pickDuration` del
/// integration_test la reconoce por la negrita).
class DurationPicker extends StatefulWidget {
  static const stepMinutes = 5;
  static const steps = 72;

  final Duration initial;

  const DurationPicker({super.key, required this.initial});

  static Future<Duration?> show(Duration initial) =>
      Get.dialog<Duration>(DurationPicker(initial: initial));

  @override
  State<DurationPicker> createState() => _DurationPickerState();
}

class _DurationPickerState extends State<DurationPicker> {
  static const _itemExtent = 50.0;

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
      icon: const Icon(Icons.timer_rounded),
      title: const Text('Duración'),
      content: SizedBox(
        height: 250,
        width: 280,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Banda de la fila elegida.
            IgnorePointer(
              child: Container(
                height: _itemExtent - 4,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: AppRadii.fieldRadius,
                ),
              ),
            ),
            ListWheelScrollView.useDelegate(
              controller: _scroll,
              itemExtent: _itemExtent,
              perspective: 0.006,
              diameterRatio: 1.6,
              physics: const FixedExtentScrollPhysics(),
              onSelectedItemChanged: (index) => setState(() => _index = index),
              childDelegate: ListWheelChildBuilderDelegate(
                childCount: DurationPicker.steps,
                builder: (context, index) {
                  final selected = index == _index;
                  return Center(
                    child: Text(
                      formatDurationMinutes(_minutesAt(index)),
                      style: (selected ? text.titleLarge : text.bodyLarge)
                          ?.copyWith(
                            fontWeight:
                                selected ? FontWeight.bold : FontWeight.normal,
                            color: selected
                                ? scheme.onPrimaryContainer
                                : scheme.onSurfaceVariant,
                          )
                          .tabular,
                    ),
                  );
                },
              ),
            ),
          ],
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
