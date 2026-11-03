import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/common/entities/work_hours.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/features/employees/presentation/controllers/employee_form_controller.dart';
import 'package:login_signup/shared/widgets/app_note.dart';
import 'package:login_signup/shared/widgets/app_pill.dart';
import 'package:login_signup/shared/widgets/time_range_card.dart';

/// Días y horas de trabajo del formulario de profesional, con el mismo
/// patrón que el horario de "Mi negocio": un bloque tonal por día con su
/// interruptor y, si trabaja, una [TimeRangeCard] por franja ("Inicio" y
/// "Fin" en 12 h), "Añadir franja" y quitar franja (13.06). Las franjas que
/// se cruzan se marcan en vivo y no dejan guardar.
class EmployeeScheduleSection extends StatelessWidget {
  final EmployeeFormController controller;

  const EmployeeScheduleSection({super.key, required this.controller});

  /// Texto bajo un día con franjas cruzadas ([indexes] desde 0).
  static String overlapText(Set<int> indexes) {
    final numbers = [for (final i in indexes.toList()..sort()) '${i + 1}'];
    final list =
        '${numbers.sublist(0, numbers.length - 1).join(', ')} y ${numbers.last}';
    return 'Las franjas $list se cruzan: una tiene que terminar antes de '
        'que empiece la otra.';
  }

  static const invalidText = 'La hora de inicio debe ser anterior a la de fin';

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final schedule = Map.of(controller.schedule);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (schedule.isEmpty)
            const AppNote(
              'Sin días marcados no hay restricción de horario: se le '
              'pueden agendar citas a cualquier hora.',
              tone: AppTone.info,
              icon: Icons.info_rounded,
              margin: EdgeInsets.only(bottom: 4),
            ),
          for (final day in WorkHours.weekdays)
            _DayRow(
              day: day,
              ranges: controller.rangesOf(day),
              controller: controller,
            ),
        ],
      );
    });
  }
}

class _DayRow extends StatelessWidget {
  final String day;
  final List<WorkHours> ranges;
  final EmployeeFormController controller;

  const _DayRow({
    required this.day,
    required this.ranges,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final label = employeeDayLabels[day] ?? day;
    final works = ranges.isNotEmpty;
    final crossed = controller.overlappingOn(day);
    final anyInvalid = ranges.any((h) => !h.isValid);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = context.tokens;
    final state = works ? tokens.success : tokens.statusCancelled;

    return AnimatedContainer(
      duration: AppMotion.of(context),
      curve: AppMotion.curve,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.fromLTRB(12, 0, 4, 4),
      decoration: BoxDecoration(
        color: works ? scheme.surfaceContainerHigh : scheme.surfaceContainerLow,
        borderRadius: AppRadii.fieldRadius,
        border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: works ? 0.7 : 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // El integration_test lo busca con `widgetWithText(SwitchListTile,
          // día)`.
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(label,
                style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: works ? scheme.onSurface : scheme.onSurfaceVariant)),
            subtitle: Align(
              alignment: Alignment.centerLeft,
              child: AppPill(
                dense: true,
                label: works ? 'Trabaja' : 'Libre',
                colors: state,
              ),
            ),
            value: works,
            onChanged: (value) => controller.setWorkDay(day, value),
          ),
          for (var i = 0; i < ranges.length; i++)
            TimeRangeCard(
              key: Key('employee-range-$day-$i'),
              startLabel: 'Inicio',
              endLabel: 'Fin',
              start: ranges[i].start,
              end: ranges[i].end,
              // La primera conserva la etiqueta de siempre (la usa
              // `setEmployeeDay` del integration_test); las demás, como en
              // Mi negocio.
              startSemantics: i == 0
                  ? '$label, hora de inicio'
                  : '$label, franja ${i + 1}, inicio',
              endSemantics: i == 0
                  ? '$label, hora de fin'
                  : '$label, franja ${i + 1}, fin',
              onStart: (v) => controller.setStart(day, v, index: i),
              onEnd: (v) => controller.setEnd(day, v, index: i),
              onRemove: () => controller.removeRange(day, i),
              removeTooltip: 'Quitar franja ${i + 1} del '
                  '${label.toLowerCase()}',
              removeKey: Key('employee-range-remove-$day-$i'),
              invalid: !ranges[i].isValid || crossed.contains(i),
            ),
          if (anyInvalid)
            _Problem(
              key: Key('employee-range-invalid-$day'),
              text: EmployeeScheduleSection.invalidText,
            ),
          if (crossed.isNotEmpty)
            _Problem(
              key: Key('employee-range-overlap-$day'),
              text: EmployeeScheduleSection.overlapText(crossed),
            ),
          if (works && controller.canAddRange(day))
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: Key('employee-add-range-$day'),
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

/// Aviso en rojo bajo las franjas de un día.
class _Problem extends StatelessWidget {
  final String text;

  const _Problem({super.key, required this.text});

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
            child: Text(
              text,
              style: TextStyle(color: scheme.error, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
