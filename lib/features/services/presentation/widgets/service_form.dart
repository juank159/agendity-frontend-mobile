import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/utils/formatters.dart';
import 'package:login_signup/features/services/domain/entities/service_price_type.dart';
import 'package:login_signup/features/services/presentation/controllers/service_form_controller.dart';
import 'package:login_signup/features/services/presentation/widgets/category_picker.dart';
import 'package:login_signup/features/services/presentation/widgets/color_picker.dart';
import 'package:login_signup/features/services/presentation/widgets/duration_picker.dart';

/// Campos del servicio, comunes al alta y a la edición.
class ServiceForm extends StatelessWidget {
  final ServiceFormController controller;

  const ServiceForm({super.key, required this.controller});

  Future<void> _pickDuration() async {
    final picked = await DurationPicker.show(controller.duration.value);
    if (picked != null) controller.duration.value = picked;
  }

  Future<void> _pickCategory() async {
    final categories = await controller.categoriesForPicker();
    if (categories.isEmpty) return;
    final picked = await CategoryPicker.show(categories,
        selectedId: controller.selectedCategory.value?.id);
    if (picked != null) controller.selectedCategory.value = picked;
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Información básica', style: text.titleMedium),
        const SizedBox(height: 16),
        TextField(
          controller: controller.nameController,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Nombre del servicio',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: controller.priceController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
          ],
          decoration: const InputDecoration(
            labelText: 'Precio',
            prefixText: '\$ ',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        Text('Tipo de precio', style: text.labelLarge),
        const SizedBox(height: 8),
        Obx(() => SegmentedButton<ServicePriceType>(
              segments: [
                for (final type in ServicePriceType.values)
                  ButtonSegment(value: type, label: Text(type.apiValue)),
              ],
              selected: {controller.priceType.value},
              onSelectionChanged: (selection) =>
                  controller.priceType.value = selection.first,
            )),
        const SizedBox(height: 16),
        Obx(() => _SelectableField(
              label: 'Duración',
              value: formatDurationMinutes(controller.duration.value.inMinutes),
              icon: Icons.schedule,
              onTap: _pickDuration,
            )),
        const SizedBox(height: 16),
        Obx(() => _SelectableField(
              label: 'Categoría',
              value: controller.selectedCategory.value?.name ??
                  'Selecciona una categoría',
              icon: Icons.folder_outlined,
              muted: controller.selectedCategory.value == null,
              onTap: _pickCategory,
            )),
        const SizedBox(height: 16),
        TextField(
          controller: controller.descriptionController,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Descripción (opcional)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 24),
        Text('Color en la agenda', style: text.titleMedium),
        const SizedBox(height: 12),
        Obx(() => ServiceColorPicker(
              selected: controller.color.value,
              onChanged: (color) => controller.color.value = color,
            )),
        const SizedBox(height: 16),
        Obx(() => SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Se puede reservar en línea'),
              value: controller.onlineBooking.value,
              onChanged: (value) => controller.onlineBooking.value = value,
            )),
        const SizedBox(height: 8),
        Obx(() => Row(
              children: [
                Expanded(
                    child: Text('Abono mínimo', style: text.bodyLarge)),
                Text('${controller.deposit.value.round()} %',
                    style: text.titleMedium?.copyWith(color: scheme.primary)),
              ],
            )),
        Obx(() => Slider(
              value: controller.deposit.value,
              min: 0,
              max: 100,
              divisions: 20,
              label: '${controller.deposit.value.round()} %',
              onChanged: (value) => controller.deposit.value = value,
            )),
      ],
    );
  }
}

class _SelectableField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool muted;
  final VoidCallback onTap;

  const _SelectableField({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          suffixIcon: const Icon(Icons.chevron_right),
          border: const OutlineInputBorder(),
        ),
        child: Text(
          value,
          style: TextStyle(
              color: muted ? scheme.onSurfaceVariant : scheme.onSurface),
        ),
      ),
    );
  }
}
