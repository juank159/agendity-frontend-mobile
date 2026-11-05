import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/common/entities/work_hours.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/core/utils/formatters.dart';
import 'package:login_signup/features/settings/domain/entities/opening_hours.dart';
import 'package:login_signup/features/settings/domain/usecases/business_settings_rules.dart';
import 'package:login_signup/features/settings/presentation/controllers/business_settings_controller.dart';
import 'package:login_signup/shared/widgets/time_range_card.dart';

/// Horario de apertura por día: abierto/cerrado y una o varias franjas
/// (p. ej. 9:00 a. m.–1:00 p. m. y 3:00–7:00 p. m.). Cada día es un bloque
/// tonal y cada franja una [TimeRangeCard] con "Abre" y "Cierra" (el
/// selector de hora de 12 h, `AppTimePicker`). Una franja que cierra antes de
/// abrir o que se cruza con otra sale en rojo al momento, con el motivo; si
/// fue por confundir a. m. con p. m., ofrece la corrección. El use case
/// vuelve a comprobar las reglas al guardar.
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
    final backwards = controller.backwardsRangesOn(day);
    final crossed = controller.crossedRangesOn(day);
    final state = closed ? tokens.statusCancelled : tokens.success;
    return AnimatedContainer(
      duration: AppMotion.of(context),
      curve: AppMotion.curve,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.fromLTRB(12, 6, 6, 8),
      decoration: BoxDecoration(
        color:
            closed ? scheme.surfaceContainerLow : scheme.surfaceContainerHigh,
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
                        color: state.onContainer, fontWeight: FontWeight.w700)),
              ),
              Switch(
                key: Key('opening-day-$day'),
                value: !closed,
                onChanged: (open) => controller.setDayOpen(day, open),
              ),
            ],
          ),
          for (var i = 0; i < ranges.length; i++)
            TimeRangeCard(
              startLabel: 'Abre',
              endLabel: 'Cierra',
              start: ranges[i].start,
              end: ranges[i].end,
              startSemantics: '$name, franja ${i + 1}, apertura',
              endSemantics: '$name, franja ${i + 1}, cierre',
              onStart: (value) => controller.updateRange(day, i, start: value),
              onEnd: (value) => controller.updateRange(day, i, end: value),
              onRemove: () => controller.removeRange(day, i),
              removeTooltip: 'Quitar franja del $name',
              invalid: backwards.contains(i) || crossed.contains(i),
            ),
          for (final i in backwards)
            _BackwardsProblem(
              key: Key('opening-backwards-$day-$i'),
              fixKey: Key('opening-backwards-$day-$i-fix'),
              hours: ranges[i],
              index: i,
              showIndex: ranges.length > 1,
              onFix: (end) => controller.updateRange(day, i, end: end),
            ),
          if (crossed.isNotEmpty)
            _Problem(
              key: Key('opening-crossed-$day'),
              text: 'Las franjas ${crossed.map((i) => i + 1).join(' y ')} '
                  'se cruzan: una debe cerrar antes de que abra la otra.',
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

/// "Cierra antes de abrir": el motivo con las dos horas y, si fue por
/// confundir a. m. con p. m., el botón que lo corrige.
class _BackwardsProblem extends StatelessWidget {
  final Key fixKey;
  final WorkHours hours;
  final int index;
  final bool showIndex;
  final ValueChanged<String> onFix;

  const _BackwardsProblem({
    super.key,
    required this.fixKey,
    required this.hours,
    required this.index,
    required this.showIndex,
    required this.onFix,
  });

  @override
  Widget build(BuildContext context) {
    final fix = BusinessSettingsController.amPmFixOf(hours);
    final which = showIndex ? 'La franja ${index + 1}' : 'La franja';
    return _Problem(
      text: '$which cierra (${formatHhmmWithMoment(hours.end)}) antes de abrir '
          '(${formatHhmmWithMoment(hours.start)}).'
          '${fix == null ? '' : ' ¿Querías decir ${formatHhmmWithMoment(fix)}?'}',
      action: fix == null
          ? null
          : TextButton.icon(
              key: fixKey,
              onPressed: () => onFix(fix),
              icon: const Icon(Icons.auto_fix_high_rounded, size: 18),
              label: Text('Cerrar a las ${formatHhmm(fix)}'),
            ),
    );
  }
}

/// Aviso en rojo bajo las franjas de un día.
class _Problem extends StatelessWidget {
  final String text;
  final Widget? action;

  const _Problem({super.key, required this.text, this.action});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 6, right: 8, bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_rounded, size: 16, color: scheme.error),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text, style: TextStyle(color: scheme.error, fontSize: 13)),
                if (action != null) action!,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
