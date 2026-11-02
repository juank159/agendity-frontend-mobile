import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/core/utils/formatters.dart';
import 'package:login_signup/features/services/domain/entities/service_price_type.dart';
import 'package:login_signup/features/services/presentation/controllers/service_form_controller.dart';
import 'package:login_signup/features/services/presentation/widgets/category_picker.dart';
import 'package:login_signup/features/services/presentation/widgets/color_picker.dart';
import 'package:login_signup/features/services/presentation/widgets/duration_picker.dart';
import 'package:login_signup/features/services/presentation/widgets/service_card.dart';
import 'package:login_signup/shared/utils/color_hex.dart';
import 'package:login_signup/shared/widgets/app_section_card.dart';
import 'package:login_signup/shared/widgets/money_field.dart';

/// Campos del servicio, comunes al alta y a la edición, en cuatro secciones:
/// datos básicos, precio y duración (el precio con `MoneyField`: "15000" se
/// ve "$ 15.000"), color en la agenda (con vista previa) y reservas.
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
    final theme = Theme.of(context);
    final text = theme.textTheme;
    final scheme = theme.colorScheme;
    return ListView(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      children: [
        AppSectionCard(
          icon: Icons.spa_rounded,
          title: 'Información básica',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: controller.nameController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Nombre del servicio',
                  prefixIcon: Icon(Icons.label_rounded),
                ),
              ),
              const SizedBox(height: 16),
              Obx(() => _SelectableField(
                    label: 'Categoría',
                    value: controller.selectedCategory.value?.name ??
                        'Selecciona una categoría',
                    icon: Icons.folder_rounded,
                    muted: controller.selectedCategory.value == null,
                    onTap: _pickCategory,
                  )),
              const SizedBox(height: 16),
              TextField(
                controller: controller.descriptionController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Descripción (opcional)',
                  prefixIcon: Icon(Icons.notes_rounded),
                ),
              ),
            ],
          ),
        ),
        AppSectionCard(
          icon: Icons.payments_rounded,
          title: 'Precio y duración',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MoneyField(
                controller: controller.priceController,
                label: 'Precio',
                hint: '0',
                icon: Icons.sell_rounded,
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
                    value: formatDurationMinutes(
                        controller.duration.value.inMinutes),
                    icon: Icons.timer_rounded,
                    emphasize: true,
                    onTap: _pickDuration,
                  )),
              const SizedBox(height: 16),
              Obx(() => Row(
                    children: [
                      Icon(Icons.savings_rounded,
                          size: 20, color: scheme.onSurfaceVariant),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text('Abono mínimo', style: text.bodyLarge)),
                      Text('${controller.deposit.value.round()} %',
                          style: text.titleMedium
                              ?.copyWith(
                                color: scheme.primary,
                                fontWeight: FontWeight.w700,
                              )
                              .tabular),
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
          ),
        ),
        AppSectionCard(
          icon: Icons.palette_rounded,
          title: 'Color en la agenda',
          subtitle: 'Así distingues este servicio en el calendario.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Obx(() => _AgendaPreview(
                    color: controller.color.value,
                    name: controller.nameController,
                  )),
              const SizedBox(height: 16),
              Obx(() => ServiceColorPicker(
                    selected: controller.color.value,
                    onChanged: (color) => controller.color.value = color,
                  )),
            ],
          ),
        ),
        AppSectionCard(
          icon: Icons.event_available_rounded,
          title: 'Reservas y recordatorios',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Obx(() => SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    secondary: const Icon(Icons.public_rounded),
                    title: const Text('Se puede reservar en línea'),
                    subtitle: const Text(
                        'Aparece en el link público de reservas del negocio '
                        'para que tus clientes lo agenden solos.'),
                    value: controller.onlineBooking.value,
                    onChanged: (value) =>
                        controller.onlineBooking.value = value,
                  )),
              const SizedBox(height: 12),
              TextField(
                key: const Key('service-maintenance-days'),
                controller: controller.maintenanceDaysController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Recordar mantenimiento a los N días (opcional)',
                  helperText: 'Ej.: 21 para un retoque de pestañas. Si lo '
                      'dejas vacío, este servicio no envía recordatorio de '
                      'mantenimiento.',
                  helperMaxLines: 2,
                  suffixText: 'días',
                  prefixIcon: Icon(Icons.autorenew_rounded),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Campo que abre un selector (categoría, duración): se ve como los campos
/// del tema, con la etiqueta flotante y una flecha al final.
class _SelectableField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool muted;

  /// Valor más grande y en negrita (la duración).
  final bool emphasize;
  final VoidCallback onTap;

  const _SelectableField({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
    this.muted = false,
    this.emphasize = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final base = emphasize ? theme.textTheme.titleMedium : theme.textTheme.bodyLarge;
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadii.fieldRadius,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          suffixIcon: const Icon(Icons.chevron_right_rounded),
        ),
        child: Text(
          value,
          style: base
              ?.copyWith(
                color: muted ? scheme.onSurfaceVariant : scheme.onSurface,
                fontWeight: emphasize ? FontWeight.w700 : null,
              )
              .tabular,
        ),
      ),
    );
  }
}

/// Vista previa del servicio en la agenda: su color con el degradado, el
/// brillo y el texto legible encima (blanco o negro según el color).
class _AgendaPreview extends StatelessWidget {
  final Color color;
  final TextEditingController name;

  const _AgendaPreview({required this.color, required this.name});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final ink = contrastOn(color);
    return Semantics(
      label: 'Vista previa en la agenda',
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 10, 14, 10),
        decoration: BoxDecoration(
          gradient: tokens.gradientOf(color),
          borderRadius: AppRadii.fieldRadius,
          border: Border.all(color: tokens.innerBorder),
          boxShadow: tokens.elevation2(tint: color),
        ),
        foregroundDecoration: BoxDecoration(
          borderRadius: AppRadii.fieldRadius,
          gradient: tokens.sheenGradient,
        ),
        child: Row(
          children: [
            ServiceColorChip(color: color, size: 32),
            const SizedBox(width: 10),
            Expanded(
              child: ValueListenableBuilder<TextEditingValue>(
                valueListenable: name,
                builder: (context, value, _) => Text(
                  value.text.trim().isEmpty
                      ? 'Tu servicio en la agenda'
                      : value.text.trim(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: ink, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            Icon(Icons.event_rounded, color: ink, size: 18),
          ],
        ),
      ),
    );
  }
}
