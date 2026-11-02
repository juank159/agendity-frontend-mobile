import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/features/settings/domain/entities/opening_hours.dart';
import 'package:login_signup/features/settings/domain/usecases/business_settings_rules.dart';
import 'package:login_signup/features/settings/presentation/controllers/business_settings_controller.dart';
import 'package:login_signup/shared/widgets/time_of_day_button.dart';

/// Horario de apertura por día: abierto/cerrado y una o varias franjas
/// (p. ej. 9:00 a. m.–1:00 p. m. y 3:00–7:00 p. m.). Cada día es un bloque
/// tonal y cada franja una tarjeta con "Abre" y "Cierra" (el selector de hora
/// de 12 h, `AppTimePicker`). Las reglas (cierre después de la apertura,
/// franjas que no se pisen) las comprueba el use case al guardar.
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
            _DayBlock(day: day, controller: controller),
        ],
      );
    });
  }
}

class _DayBlock extends StatelessWidget {
  final int day;
  final BusinessSettingsController controller;

  const _DayBlock({required this.day, required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = context.tokens;
    final name = OpeningHoursEditor.dayName(day);
    final closed = controller.isClosedOn(day);
    final ranges = controller.rangesOn(day);
    final state = closed ? tokens.statusCancelled : tokens.success;
    return AnimatedContainer(
      duration: AppMotion.of(context),
      curve: AppMotion.curve,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.fromLTRB(12, 6, 6, 8),
      decoration: BoxDecoration(
        color: closed ? scheme.surfaceContainerLow : scheme.surfaceContainerHigh,
        borderRadius: AppRadii.fieldRadius,
        border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: closed ? 0.4 : 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(name,
                    style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: closed
                            ? scheme.onSurfaceVariant
                            : scheme.onSurface)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: state.container,
                  borderRadius: AppRadii.chipRadius,
                ),
                child: Text(closed ? 'Cerrado' : 'Abierto',
                    style: theme.textTheme.labelSmall?.copyWith(
                        color: state.onContainer,
                        fontWeight: FontWeight.w700)),
              ),
              Switch(
                key: Key('opening-day-$day'),
                value: !closed,
                onChanged: (open) => controller.setDayOpen(day, open),
              ),
            ],
          ),
          for (var i = 0; i < ranges.length; i++)
            _RangeCard(
              name: name,
              index: i,
              start: ranges[i].start,
              end: ranges[i].end,
              onStart: (value) => controller.updateRange(day, i, start: value),
              onEnd: (value) => controller.updateRange(day, i, end: value),
              onRemove: () => controller.removeRange(day, i),
            ),
          if (!closed)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: Key('opening-add-$day'),
                onPressed: () => controller.addRange(day),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Añadir franja'),
              ),
            ),
        ],
      ),
    );
  }
}

/// Una franja del día: tarjeta con "Abre" y "Cierra" y el botón de quitarla.
class _RangeCard extends StatelessWidget {
  final String name;
  final int index;
  final String start;
  final String end;
  final ValueChanged<String> onStart;
  final ValueChanged<String> onEnd;
  final VoidCallback onRemove;

  const _RangeCard({
    required this.name,
    required this.index,
    required this.start,
    required this.end,
    required this.onStart,
    required this.onEnd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = context.tokens;
    return Container(
      margin: const EdgeInsets.only(top: 6, right: 6),
      padding: const EdgeInsets.fromLTRB(8, 8, 2, 8),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: AppRadii.fieldRadius,
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
        boxShadow: tokens.elevation1(),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 36,
            decoration: BoxDecoration(
              gradient: tokens.primaryGradient,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                TimeOfDayButton(
                  label: 'Abre',
                  value: start,
                  semantics: '$name, franja ${index + 1}, apertura',
                  onPicked: onStart,
                ),
                TimeOfDayButton(
                  label: 'Cierra',
                  value: end,
                  semantics: '$name, franja ${index + 1}, cierre',
                  onPicked: onEnd,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline_rounded),
            color: scheme.error,
            tooltip: 'Quitar franja del $name',
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}
