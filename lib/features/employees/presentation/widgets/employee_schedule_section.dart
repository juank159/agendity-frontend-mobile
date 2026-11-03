import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/common/entities/work_hours.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/features/employees/presentation/controllers/employee_form_controller.dart';
import 'package:login_signup/shared/widgets/app_note.dart';
import 'package:login_signup/shared/widgets/app_pill.dart';
import 'package:login_signup/shared/widgets/time_of_day_button.dart';

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

/// Días y horas de trabajo del formulario de profesional: un bloque tonal
/// por día con su interruptor y, si trabaja, la franja con "Inicio" y "Fin"
/// en 12 h (`TimeOfDayButton` → `AppTimePicker`).
class EmployeeScheduleSection extends StatelessWidget {
  final EmployeeFormController controller;

  const EmployeeScheduleSection({super.key, required this.controller});

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
              // La primera franja; las demás se conservan en el controller
              // (13.06 las muestra todas).
              hours: controller.rangesOf(day).firstOrNull,
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
    final works = hours != null;
    final invalid = hours != null && !hours.isValid;
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
          if (hours != null) ...[
            Container(
              margin: const EdgeInsets.only(right: 8, bottom: 6),
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: AppRadii.fieldRadius,
                border: Border.all(
                    color: invalid
                        ? scheme.error
                        : scheme.outlineVariant.withValues(alpha: 0.6)),
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
                    child: TimeOfDayButton(
                      label: 'Inicio',
                      value: hours.start,
                      semantics: '$label, hora de inicio',
                      onPicked: (v) => controller.setStart(day, v),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TimeOfDayButton(
                      label: 'Fin',
                      value: hours.end,
                      semantics: '$label, hora de fin',
                      onPicked: (v) => controller.setEnd(day, v),
                    ),
                  ),
                ],
              ),
            ),
            if (invalid)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(Icons.error_rounded, size: 16, color: scheme.error),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'La hora de inicio debe ser anterior a la de fin',
                        style: TextStyle(color: scheme.error, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}
