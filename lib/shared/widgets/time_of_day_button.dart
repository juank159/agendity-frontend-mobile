import 'package:flutter/material.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/core/utils/formatters.dart';
import 'package:login_signup/shared/widgets/app_time_picker.dart';

/// Botón "Abre: 9:00 a. m." (D-23: la hora se ve en 12 h) que abre
/// [AppTimePicker] y devuelve la hora elegida en `HH:mm` (24 h, el formato
/// del contrato y de `WorkHours`). Lo usan el horario de los profesionales,
/// el horario del negocio, la ventana de recordatorios y el diálogo de regla.
class TimeOfDayButton extends StatelessWidget {
  final String label;

  /// Hora actual en `HH:mm`.
  final String value;
  final String semantics;
  final ValueChanged<String> onPicked;

  /// Paso de los minutos en la rueda.
  final int minuteStep;

  const TimeOfDayButton({
    super.key,
    required this.label,
    required this.value,
    required this.semantics,
    required this.onPicked,
    this.minuteStep = 5,
  });

  TimeOfDay get _initial {
    final parts = value.split(':');
    return TimeOfDay(
      hour: (int.tryParse(parts.first) ?? 9).clamp(0, 23),
      minute: parts.length > 1 ? (int.tryParse(parts[1]) ?? 0).clamp(0, 59) : 0,
    );
  }

  /// `TimeOfDay` → `HH:mm`.
  static String format(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:'
      '${time.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semantics,
      child: OutlinedButton.icon(
        icon: const Icon(Icons.schedule_rounded, size: 18),
        label: Text('$label: ${formatHhmm(value)}',
            style: const TextStyle().tabular),
        onPressed: () async {
          final picked = await AppTimePicker.show(context,
              initial: _initial, minuteStep: minuteStep, title: semantics);
          if (picked == null) return;
          onPicked(format(picked));
        },
      ),
    );
  }
}
