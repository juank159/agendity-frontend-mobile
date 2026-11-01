import 'package:flutter/material.dart';

/// Selector de hora de la app: **siempre en 24 h**.
///
/// En `es` el selector de Material pinta 24 h, pero su modo de texto
/// interpreta la hora escrita según `MediaQuery.alwaysUse24HourFormat`: en
/// 12 h (el ajuste del dispositivo, o el que fuerza `main.dart`), "19" da
/// "Indica una hora válida" (hallazgo de 7.05). Aquí se fija 24 h solo para
/// el selector. Todo `showTimePicker` de la app pasa por esta función.
Future<TimeOfDay?> showAppTimePicker(
  BuildContext context,
  TimeOfDay initialTime,
) =>
    showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );

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
          final picked = await showAppTimePicker(context, _initial);
          if (picked == null) return;
          onPicked(format(picked));
        },
      ),
    );
  }
}
