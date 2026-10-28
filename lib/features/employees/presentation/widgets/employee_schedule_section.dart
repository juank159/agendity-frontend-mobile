import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/features/employees/domain/entities/work_hours.dart';
import 'package:login_signup/features/employees/presentation/controllers/employee_form_controller.dart';

/// Nombre en español de los días del horario (`WorkHours.weekdays`).
const employeeDayLabels = {
  'monday': 'Lunes',
  'tuesday': 'Martes',
  'wednesday': 'Miércoles',
  'thursday': 'Jueves',
  'friday': 'Viernes',
  'saturday': 'Sábado',
  'sunday': 'Domingo',
};

/// Días y horas de trabajo del formulario de profesional.
class EmployeeScheduleSection extends StatelessWidget {
  final EmployeeFormController controller;

  const EmployeeScheduleSection({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Obx(() {
      final schedule = Map.of(controller.schedule);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (schedule.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Sin días marcados no hay restricción de horario: se le '
                'pueden agendar citas a cualquier hora.',
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            ),
          for (final day in WorkHours.weekdays)
            _DayRow(
              day: day,
              hours: schedule[day],
              controller: controller,
            ),
        ],
      );
    });
  }
}

class _DayRow extends StatelessWidget {
  final String day;
  final WorkHours? hours;
  final EmployeeFormController controller;

  const _DayRow({
    required this.day,
    required this.hours,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final label = employeeDayLabels[day] ?? day;
    final hours = this.hours;
    final invalid = hours != null && !hours.isValid;
    final scheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(label,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              value: hours != null,
              onChanged: (value) => controller.setWorkDay(day, value),
            ),
            if (hours != null) ...[
              Row(
                children: [
                  Expanded(
                    child: _TimeButton(
                      label: 'Inicio',
                      value: hours.start,
                      semantics: '$label, hora de inicio',
                      onPicked: (v) => controller.setStart(day, v),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('a'),
                  ),
                  Expanded(
                    child: _TimeButton(
                      label: 'Fin',
                      value: hours.end,
                      semantics: '$label, hora de fin',
                      onPicked: (v) => controller.setEnd(day, v),
                    ),
                  ),
                ],
              ),
              if (invalid)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'La hora de inicio debe ser anterior a la de fin',
                    style: TextStyle(color: scheme.error, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _TimeButton extends StatelessWidget {
  final String label;
  final String value;
  final String semantics;
  final ValueChanged<String> onPicked;

  const _TimeButton({
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
          onPicked('${picked.hour.toString().padLeft(2, '0')}:'
              '${picked.minute.toString().padLeft(2, '0')}');
        },
      ),
    );
  }
}
