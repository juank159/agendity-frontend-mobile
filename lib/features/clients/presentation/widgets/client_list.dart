import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/widgets/list_state_view.dart';
import 'package:login_signup/features/clients/domain/entities/client_entity.dart';
import '../controllers/clients_controller.dart';
import 'client_card.dart';

/// Lista paginada (scroll infinito) con sus estados de carga, error y vacío.
class ClientList extends GetView<ClientsController> {
  const ClientList({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final filtered = controller.hasActiveFilters;
      return ListStateView<ClientEntity>(
        isLoading: controller.isLoading.value,
        error: controller.error.value,
        items: controller.clients.toList(),
        onRetry: controller.loadClients,
        loadingMessage: 'Cargando clientes…',
        emptyIcon: filtered ? Icons.search_off : Icons.people_outline,
        emptyMessage:
            filtered ? 'Ningún cliente coincide' : 'Aún no tienes clientes',
        emptySubMessage: filtered
            ? 'Prueba con otra búsqueda o quita los filtros.'
            : 'Crea uno o importa tus contactos.',
        emptyActionLabel: filtered ? 'Quitar filtros' : 'Nuevo cliente',
        emptyActionIcon: filtered ? Icons.filter_alt_off : Icons.person_add,
        onEmptyAction:
            filtered ? controller.clearAllFilters : controller.openNewClient,
        builder: (context, clients) => RefreshIndicator(
          onRefresh: controller.refreshFromServer,
          child: ListView.builder(
            controller: controller.scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            itemCount: clients.length + 1,
            itemBuilder: (context, index) {
              if (index == clients.length) return const _ListFooter();
              final client = clients[index];
              return ClientCard(
                client: client,
                onTap: () => controller.openClient(client),
              );
            },
          ),
        ),
      );
    });
  }
}

class _ListFooter extends GetView<ClientsController> {
  const _ListFooter();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() {
      if (controller.isLoadingMore.value) {
        return const Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        );
      }
      if (controller.hasNextPage.value) return const SizedBox(height: 48);
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          '${controller.totalRecords.value} clientes',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      );
    });
  }
}
