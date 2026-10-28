import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/utils/formatters.dart';
import 'package:login_signup/features/appointments/presentation/controllers/appointment_form_controller.dart';

/// Horas libres del día elegido (las del backend: lo que se ofrece es lo que
/// se puede agendar). La hora actual de una cita que se edita se marca.
class SlotPicker extends StatelessWidget {
  final AppointmentFormController controller;

  const SlotPicker({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Obx(() {
      switch (controller.slotsStatus.value) {
        case SlotsStatus.idle:
          return _Hint(
              'Elige el profesional y los servicios para ver las horas libres.',
              color: scheme.onSurfaceVariant);
        case SlotsStatus.loading:
          return const Padding(
            padding: EdgeInsets.all(12),
            child: Center(child: CircularProgressIndicator()),
          );
        case SlotsStatus.error:
          return Row(
            children: [
              Expanded(
                child: _Hint(
                    controller.slotsError.value ??
                        'No se pudieron cargar las horas libres',
                    color: scheme.error),
              ),
              TextButton(
                onPressed: controller.loadSlots,
                child: const Text('Reintentar'),
              ),
            ],
          );
        case SlotsStatus.ready:
          final slots = controller.slots;
          if (slots.isEmpty) {
            return _Hint('No hay horas libres este día. Prueba con otro.',
                color: scheme.onSurfaceVariant);
          }
          final selected = controller.slot.value;
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in slots)
                ChoiceChip(
                  key: ValueKey('slot-${s.toIso8601String()}'),
                  label: Text(controller.isCurrentSlot(s)
                      ? '${formatTime(s)} (actual)'
                      : formatTime(s)),
                  selected: selected != null && s.isAtSameMomentAs(selected),
                  onSelected: (_) => controller.selectSlot(s),
                ),
            ],
          );
      }
    });
  }
}

class _Hint extends StatelessWidget {
  final String text;
  final Color color;

  const _Hint(this.text, {required this.color});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(text, style: TextStyle(color: color)),
      );
}
