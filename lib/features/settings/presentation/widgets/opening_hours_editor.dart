import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/features/settings/domain/entities/opening_hours.dart';
import 'package:login_signup/features/settings/domain/usecases/business_settings_rules.dart';
import 'package:login_signup/features/settings/presentation/controllers/business_settings_controller.dart';
import 'package:login_signup/shared/widgets/time_of_day_button.dart';

/// Horario de apertura por día: abierto/cerrado y una o varias franjas
/// (p. ej. 9:00–13:00 y 15:00–19:00). Las reglas (cierre después de la
/// apertura, franjas que no se pisen) las comprueba el use case al guardar.
class OpeningHoursEditor extends StatelessWidget {
  final BusinessSettingsController controller;

  const OpeningHoursEditor({super.key, required this.controller});

  static String dayName(int day) {
    final name = BusinessSettingsRules.dayNames[day - 1];
    return '${name[0].toUpperCase()}${name.substring(1)}';
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      controller.draftHours.value; // se repinta con cada cambio
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var day = OpeningHoursRange.monday;
              day <= OpeningHoursRange.sunday;
              day++)
            _DayRow(day: day, controller: controller),
        ],
      );
    });
  }
}

class _DayRow extends StatelessWidget {
  final int day;
  final BusinessSettingsController controller;

  const _DayRow({required this.day, required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final name = OpeningHoursEditor.dayName(day);
    final closed = controller.isClosedOn(day);
    final ranges = controller.rangesOn(day);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Divider(height: 1),
          Row(
            children: [
              Expanded(
                child: Text(name,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ),
              Text(closed ? 'Cerrado' : 'Abierto',
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: closed ? scheme.error : scheme.onSurfaceVariant)),
              Switch(
                key: Key('opening-day-$day'),
                value: !closed,
                onChanged: (open) => controller.setDayOpen(day, open),
              ),
            ],
          ),
          for (var i = 0; i < ranges.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  TimeOfDayButton(
                    label: 'Abre',
                    value: ranges[i].start,
                    semantics: '$name, franja ${i + 1}, apertura',
                    onPicked: (value) =>
                        controller.updateRange(day, i, start: value),
                  ),
                  TimeOfDayButton(
                    label: 'Cierra',
                    value: ranges[i].end,
                    semantics: '$name, franja ${i + 1}, cierre',
                    onPicked: (value) =>
                        controller.updateRange(day, i, end: value),
                  ),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    tooltip: 'Quitar franja del $name',
                    onPressed: () => controller.removeRange(day, i),
                  ),
                ],
              ),
            ),
          if (!closed)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: Key('opening-add-$day'),
                onPressed: () => controller.addRange(day),
                icon: const Icon(Icons.add),
                label: const Text('Añadir franja'),
              ),
            ),
        ],
      ),
    );
  }
}
