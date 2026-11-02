import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/core/utils/formatters.dart';
import 'package:login_signup/core/widgets/loading_state.dart';
import 'package:login_signup/features/appointments/presentation/controllers/appointment_form_controller.dart';
import 'package:login_signup/shared/widgets/app_note.dart';

/// Franja del día de una hora libre (para agruparlas en el formulario).
enum SlotPeriod {
  morning('Mañana', Icons.wb_sunny_rounded),
  afternoon('Tarde', Icons.wb_twilight_rounded),
  evening('Noche', Icons.nights_stay_rounded);

  final String label;
  final IconData icon;
  const SlotPeriod(this.label, this.icon);

  /// Antes de las 12:00, mañana; hasta las 18:00, tarde; luego, noche (hora
  /// de pared del negocio).
  static SlotPeriod of(DateTime slot) => slot.hour < 12
      ? SlotPeriod.morning
      : slot.hour < 18
          ? SlotPeriod.afternoon
          : SlotPeriod.evening;
}

/// Horas libres del día elegido (las del backend: lo que se ofrece es lo que
/// se puede agendar), en 12 h y agrupadas por mañana, tarde y noche. La hora
/// actual de una cita que se edita se marca "(actual)".
///
/// Cada hora es un `ChoiceChip` con `Key('slot-<ISO>')` y un `Text` como
/// etiqueta: los integration_test los buscan así (son los únicos
/// `ChoiceChip` del formulario).
class SlotPicker extends StatelessWidget {
  final AppointmentFormController controller;

  const SlotPicker({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      switch (controller.slotsStatus.value) {
        case SlotsStatus.idle:
          return const AppNote(
            'Elige el profesional y los servicios para ver las horas libres.',
            tone: AppTone.info,
            icon: Icons.touch_app_rounded,
          );
        case SlotsStatus.loading:
          return const _SlotsSkeleton();
        case SlotsStatus.error:
          return AppNote(
            controller.slotsError.value ??
                'No se pudieron cargar las horas libres',
            tone: AppTone.error,
            icon: Icons.error_outline_rounded,
            trailing: TextButton.icon(
              onPressed: controller.loadSlots,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          );
        case SlotsStatus.ready:
          final slots = controller.slots;
          if (slots.isEmpty) {
            return const AppNote(
              'No hay horas libres este día. Prueba con otro.',
              tone: AppTone.warning,
              icon: Icons.event_busy_rounded,
            );
          }
          final selected = controller.slot.value;
          final groups = <SlotPeriod, List<DateTime>>{};
          for (final s in slots) {
            groups.putIfAbsent(SlotPeriod.of(s), () => []).add(s);
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final entry in groups.entries) ...[
                _PeriodLabel(period: entry.key, count: entry.value.length),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final s in entry.value)
                      _SlotChip(
                        slot: s,
                        current: controller.isCurrentSlot(s),
                        selected:
                            selected != null && s.isAtSameMomentAs(selected),
                        onSelected: () => controller.selectSlot(s),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ],
          );
      }
    });
  }
}

class _PeriodLabel extends StatelessWidget {
  final SlotPeriod period;
  final int count;

  const _PeriodLabel({required this.period, required this.count});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(period.icon, size: 16, color: scheme.primary),
          const SizedBox(width: 6),
          Text(period.label,
              style: theme.textTheme.labelLarge
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(width: 6),
          Text('· $count',
              style: theme.textTheme.labelMedium
                  ?.copyWith(color: scheme.onSurfaceVariant)
                  .tabular),
        ],
      ),
    );
  }
}

class _SlotChip extends StatelessWidget {
  final DateTime slot;
  final bool current;
  final bool selected;
  final VoidCallback onSelected;

  const _SlotChip({
    required this.slot,
    required this.current,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final style = theme.textTheme.labelLarge
        ?.copyWith(
          fontWeight: FontWeight.w700,
          color: selected ? scheme.onPrimaryContainer : scheme.onSurface,
        )
        .tabular;
    return ChoiceChip(
      key: ValueKey('slot-${slot.toIso8601String()}'),
      showCheckmark: false,
      avatar: selected
          ? Icon(Icons.check_circle_rounded,
              size: 18, color: scheme.onPrimaryContainer)
          : null,
      label: Text(
        current ? '${formatTime(slot)} (actual)' : formatTime(slot),
        style: style,
      ),
      selected: selected,
      side: selected
          ? BorderSide(color: scheme.primary, width: 1.4)
          : null,
      onSelected: (_) => onSelected(),
    );
  }
}

/// Esqueleto de las horas mientras se piden.
class _SlotsSkeleton extends StatelessWidget {
  const _SlotsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Cargando horas libres',
      child: SkeletonShimmer(
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < 8; i++)
              const SkeletonBox(
                width: 92,
                height: 36,
                borderRadius: AppRadii.chipRadius,
              ),
          ],
        ),
      ),
    );
  }
}
