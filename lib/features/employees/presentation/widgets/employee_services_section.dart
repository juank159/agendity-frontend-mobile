import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/utils/formatters.dart';
import 'package:login_signup/core/widgets/empty_state.dart';
import 'package:login_signup/core/widgets/error_state.dart';
import 'package:login_signup/core/widgets/loading_state.dart';
import 'package:login_signup/features/employees/presentation/controllers/employee_form_controller.dart';
import 'package:login_signup/features/services/domain/entities/service_entity.dart';

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
              height: 120,
              child: LoadingState(message: 'Cargando servicios…'));
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
                icon: Icons.spa_outlined,
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
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(category,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            for (final service in services) ...[
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(service.name),
                subtitle: Text(formatCop(service.price),
                    style: TextStyle(color: scheme.onSurfaceVariant)),
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
    return Padding(
      padding: const EdgeInsets.only(left: 16),
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
          if (own != null)
            Row(
              children: [
                const Text('Propia'),
                Expanded(
                  child: Slider(
                    key: Key('commission-own-$serviceId'),
                    value: own,
                    max: 100,
                    divisions: 100,
                    label: formatPercent(own),
                    semanticFormatterCallback: (v) =>
                        'Comisión ${formatPercent(v)}',
                    onChanged: (v) => controller.setCommission(serviceId, v),
                  ),
                ),
                SizedBox(
                  width: 56,
                  child: Text(formatPercent(own), textAlign: TextAlign.end),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
