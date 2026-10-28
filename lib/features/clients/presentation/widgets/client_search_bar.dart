import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/features/clients/domain/entities/clients_query.dart';
import '../controller/clients_controller.dart';

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
                child: TextField(
                  controller: controller.searchController,
                  onChanged: (value) => controller.searchQuery.value = value,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Buscar por nombre, teléfono o email',
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                    isDense: true,
                    suffixIcon: Obx(() => controller.searchQuery.value.isEmpty
                        ? const SizedBox.shrink()
                        : IconButton(
                            icon: const Icon(Icons.clear),
                            tooltip: 'Borrar búsqueda',
                            onPressed: () {
                              controller.searchController.clear();
                              controller.searchQuery.value = '';
                            },
                          )),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                icon: const Icon(Icons.tune),
                tooltip: 'Filtros',
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  showDragHandle: true,
                  builder: (_) => const _FiltersSheet(),
                ),
              ),
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
              if (controller.sort.value != ClientsController.defaultSort)
                InputChip(
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
    Widget title(String text) => Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 8),
          child: Text(text, style: theme.textTheme.titleSmall),
        );
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Obx(() => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                title('Estado'),
                Wrap(spacing: 8, children: [
                  for (final value in ClientStatusFilter.values)
                    ChoiceChip(
                      label: Text(_statusLabel(value)),
                      selected: controller.statusFilter.value == value,
                      onSelected: (_) => controller.applyStatusFilter(value),
                    ),
                ]),
                title('Origen'),
                Wrap(spacing: 8, children: [
                  for (final value in ClientSourceFilter.values)
                    ChoiceChip(
                      label: Text(_sourceLabel(value)),
                      selected: controller.sourceFilter.value == value,
                      onSelected: (_) => controller.applySourceFilter(value),
                    ),
                ]),
                title('Ordenar por'),
                Wrap(spacing: 8, children: [
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
                    icon: const Icon(Icons.filter_alt_off),
                    label: const Text('Quitar filtros'),
                  ),
                ),
              ],
            )),
      ),
    );
  }
}
