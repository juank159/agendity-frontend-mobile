import 'package:flutter/material.dart';

/// Botón "Inicio: 09:00" que abre el selector de hora y devuelve `HH:mm`.
/// Lo usan el horario de los profesionales (employees) y el horario de
/// apertura del negocio (settings).
class TimeOfDayButton extends StatelessWidget {
  final String label;

  /// Hora actual en `HH:mm`.
  final String value;
  final String semantics;
  final ValueChanged<String> onPicked;

  const TimeOfDayButton({
    super.key,
    required this.label,
    required this.value,
    required this.semantics,
    required this.onPicked,
  });

  TimeOfDay get _initial {
    final parts = value.split(':');
    return TimeOfDay(
      hour: int.tryParse(parts.first) ?? 9,
      minute: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
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
        icon: const Icon(Icons.access_time, size: 18),
        label: Text('$label: $value'),
        onPressed: () async {
          final picked =
              await showTimePicker(context: context, initialTime: _initial);
          if (picked == null) return;
          onPicked(format(picked));
        },
      ),
    );
  }
}
