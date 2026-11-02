import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/features/clients/domain/entities/clients_query.dart';
import 'package:login_signup/shared/widgets/app_search_field.dart';
import 'package:login_signup/shared/widgets/app_sheet.dart';
import '../controllers/clients_controller.dart';

String _statusLabel(ClientStatusFilter value) => switch (value) {
      ClientStatusFilter.all => 'Todos',
      ClientStatusFilter.active => 'Activos',
      ClientStatusFilter.inactive => 'Inactivos',
    };

String _sourceLabel(ClientSourceFilter value) => switch (value) {
      ClientSourceFilter.all => 'Todos',
      ClientSourceFilter.imported => 'Importados de contactos',
      ClientSourceFilter.manual => 'Creados a mano',
    };

/// Búsqueda (en el servidor) y botón de filtros, con los filtros activos.
class ClientSearchBar extends GetView<ClientsController> {
  const ClientSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: AppSearchField(
                  controller: controller.searchController,
                  hint: 'Buscar por nombre, teléfono o email',
                  onChanged: (value) => controller.searchQuery.value = value,
                ),
              ),
              const SizedBox(width: 8),
              Obx(() => Badge(
                    // Filtros de la hoja (la búsqueda ya se ve en el campo).
                    isLabelVisible: controller.statusFilter.value !=
                            ClientStatusFilter.all ||
                        controller.sourceFilter.value !=
                            ClientSourceFilter.all ||
                        controller.withoutConsent.value ||
                        controller.sort.value != ClientsController.defaultSort,
                    smallSize: 10,
                    child: IconButton.filledTonal(
                      icon: const Icon(Icons.tune_rounded),
                      tooltip: 'Filtros',
                      onPressed: () => AppSheet.show<void>(
                        context,
                        title: 'Filtrar clientes',
                        icon: Icons.tune_rounded,
                        builder: (_) => const _FiltersSheet(),
                      ),
                    ),
                  )),
            ],
          ),
          Obx(() {
            final chips = <Widget>[
              if (controller.statusFilter.value != ClientStatusFilter.all)
                InputChip(
                  label: Text(_statusLabel(controller.statusFilter.value)),
                  onDeleted: () =>
                      controller.applyStatusFilter(ClientStatusFilter.all),
                ),
              if (controller.sourceFilter.value != ClientSourceFilter.all)
                InputChip(
                  label: Text(_sourceLabel(controller.sourceFilter.value)),
                  onDeleted: () =>
                      controller.applySourceFilter(ClientSourceFilter.all),
                ),
              if (controller.withoutConsent.value)
                InputChip(
                  label: const Text('Sin consentimiento'),
                  onDeleted: () => controller.applyWithoutConsent(false),
                ),
              if (controller.sort.value != ClientsController.defaultSort)
                InputChip(
                  avatar: const Icon(Icons.sort_rounded, size: 18),
                  label: Text(controller.sort.value.label),
                  onDeleted: () =>
                      controller.applySort(ClientsController.defaultSort),
                ),
            ];
            if (chips.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Wrap(spacing: 8, runSpacing: 4, children: chips),
            );
          }),
        ],
      ),
    );
  }
}

class _FiltersSheet extends GetView<ClientsController> {
  const _FiltersSheet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget title(String text, IconData icon) => Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 8),
          child: Row(
            children: [
              Icon(icon, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(text,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
        );
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Obx(() => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              title('Estado', Icons.toggle_on_rounded),
              Wrap(spacing: 8, runSpacing: 4, children: [
                for (final value in ClientStatusFilter.values)
                  ChoiceChip(
                    label: Text(_statusLabel(value)),
                    selected: controller.statusFilter.value == value,
                    onSelected: (_) => controller.applyStatusFilter(value),
                  ),
              ]),
              title('Origen', Icons.contacts_rounded),
              Wrap(spacing: 8, runSpacing: 4, children: [
                for (final value in ClientSourceFilter.values)
                  ChoiceChip(
                    label: Text(_sourceLabel(value)),
                    selected: controller.sourceFilter.value == value,
                    onSelected: (_) => controller.applySourceFilter(value),
                  ),
              ]),
              title('WhatsApp', Icons.mark_chat_read_rounded),
              FilterChip(
                key: const Key('filter-without-consent'),
                label: const Text('Sin consentimiento'),
                tooltip: 'Clientes a los que aún no has pedido permiso '
                    'para los recordatorios por WhatsApp',
                selected: controller.withoutConsent.value,
                onSelected: controller.applyWithoutConsent,
              ),
              title('Ordenar por', Icons.sort_rounded),
              Wrap(spacing: 8, runSpacing: 4, children: [
                for (final value in ClientSortOption.values)
                  ChoiceChip(
                    label: Text(value.label),
                    selected: controller.sort.value == value,
                    onSelected: (_) => controller.applySort(value),
                  ),
              ]),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: controller.hasActiveFilters
                      ? controller.clearAllFilters
                      : null,
                  icon: const Icon(Icons.filter_alt_off_rounded),
                  label: const Text('Quitar filtros'),
                ),
              ),
            ],
          )),
    );
  }
}
