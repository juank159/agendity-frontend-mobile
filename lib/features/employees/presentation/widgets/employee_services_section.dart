import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/core/utils/formatters.dart';
import 'package:login_signup/core/widgets/empty_state.dart';
import 'package:login_signup/core/widgets/error_state.dart';
import 'package:login_signup/core/widgets/loading_state.dart';
import 'package:login_signup/features/employees/presentation/controllers/employee_form_controller.dart';
import 'package:login_signup/features/services/domain/entities/service_entity.dart';
import 'package:login_signup/shared/utils/color_hex.dart';
import 'package:login_signup/shared/widgets/app_pill.dart';

/// Servicios que atiende el profesional, agrupados por categoría. Cada uno
/// usa la comisión general o una propia (0–100 %, D-16).
class EmployeeServicesSection extends StatelessWidget {
  final EmployeeFormController controller;

  const EmployeeServicesSection({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      switch (controller.catalogStatus.value) {
        case EmployeeLoadStatus.loading:
          return const SizedBox(
              height: 160, child: LoadingState(message: 'Cargando servicios…'));
        case EmployeeLoadStatus.error:
          return SizedBox(
            height: 260,
            child: ErrorState(
              message: controller.catalogError.value ?? '',
              onRetry: controller.loadCatalog,
            ),
          );
        case EmployeeLoadStatus.ready:
          final grouped = controller.catalogByCategory;
          if (grouped.isEmpty) {
            return const SizedBox(
              height: 260,
              child: EmptyState(
                icon: Icons.spa_rounded,
                message: 'No hay servicios',
                subMessage: 'Crea servicios en el catálogo para asignarlos.',
              ),
            );
          }
          // Lee el mapa para que el Obx reaccione a la selección.
          final selected = Map.of(controller.commissions);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final entry in grouped.entries)
                _CategoryCard(
                  category: entry.key,
                  services: entry.value,
                  selected: selected,
                  controller: controller,
                ),
            ],
          );
      }
    });
  }
}

/// Bloque tonal de una categoría con sus servicios: cada uno se marca con
/// su casilla (nombre, precio y duración) y, si está marcado, su comisión.
class _CategoryCard extends StatelessWidget {
  final String category;
  final List<ServiceEntity> services;
  final Map<String, double?> selected;
  final EmployeeFormController controller;

  const _CategoryCard({
    required this.category,
    required this.services,
    required this.selected,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final chosen = services.where((s) => selected.containsKey(s.id)).length;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: AppRadii.fieldRadius,
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.folder_rounded, size: 18, color: scheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(category,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ),
              if (chosen > 0)
                AppPill(
                  dense: true,
                  tabular: true,
                  label: '$chosen de ${services.length}',
                  colors: ToneColors(
                    color: scheme.primary,
                    container: scheme.primaryContainer,
                    onContainer: scheme.onPrimaryContainer,
                  ),
                ),
            ],
          ),
          for (final service in services) ...[
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(service.name),
              subtitle: Text(
                  '${formatCop(service.price)} · '
                  '${formatDurationMinutes(service.duration)}',
                  style: TextStyle(color: scheme.onSurfaceVariant).tabular),
              secondary: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: colorFromHex(service.color),
                  shape: BoxShape.circle,
                ),
              ),
              value: selected.containsKey(service.id),
              onChanged: (_) => controller.toggleService(service.id!),
            ),
            if (selected.containsKey(service.id))
              _CommissionEditor(
                serviceId: service.id!,
                exception: selected[service.id],
                controller: controller,
              ),
          ],
        ],
      ),
    );
  }
}

/// "Usar la general (X %)" o una comisión propia del servicio.
class _CommissionEditor extends StatelessWidget {
  final String serviceId;

  /// `null` = usa la general.
  final double? exception;
  final EmployeeFormController controller;

  const _CommissionEditor({
    required this.serviceId,
    required this.exception,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final own = exception;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(40, 0, 4, 8),
      padding: const EdgeInsets.fromLTRB(12, 0, 8, 4),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: AppRadii.chipRadius,
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Obx(() {
            final general = controller.generalCommission.value;
            return SwitchListTile(
              key: Key('commission-general-$serviceId'),
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text(general.isNaN
                  ? 'Usar la general'
                  : 'Usar la general (${formatPercent(general)})'),
              value: own == null,
              onChanged: (value) =>
                  controller.useGeneralCommission(serviceId, value),
            );
          }),
          if (own != null) ...[
            // Fila propia para el ajuste fino (±1 %) y el deslizador a todo
            // el ancho: en un móvil angosto 0–100 cabía en ~90 px.
            Row(
              children: [
                Text('Propia', style: theme.textTheme.bodyMedium),
                const Spacer(),
                IconButton(
                  tooltip: 'Bajar comisión',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.remove_circle_outline_rounded),
                  onPressed: own <= 0
                      ? null
                      : () => controller.setCommission(
                          serviceId, (own - 1).clamp(0, 100).roundToDouble()),
                ),
                SizedBox(
                  width: 56,
                  child: Text(formatPercent(own),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(
                            color: scheme.primary,
                            fontWeight: FontWeight.w700,
                          )
                          .tabular),
                ),
                IconButton(
                  tooltip: 'Subir comisión',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.add_circle_outline_rounded),
                  onPressed: own >= 100
                      ? null
                      : () => controller.setCommission(
                          serviceId, (own + 1).clamp(0, 100).roundToDouble()),
                ),
              ],
            ),
            Slider(
              key: Key('commission-own-$serviceId'),
              value: own,
              max: 100,
              divisions: 100,
              label: formatPercent(own),
              semanticFormatterCallback: (v) => 'Comisión ${formatPercent(v)}',
              onChanged: (v) => controller.setCommission(serviceId, v),
            ),
          ],
        ],
      ),
    );
  }
}
