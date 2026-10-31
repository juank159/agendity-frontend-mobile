import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/widgets/list_state_view.dart';
import '../../domain/entities/service_entity.dart';
import '../controllers/services_controller.dart';
import '../widgets/service_card.dart';

/// Catálogo de servicios agrupado por categoría. El Employee lo ve en solo
/// lectura (sin crear ni editar).
class ServicesScreen extends GetView<ServicesController> {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Servicios'),
        actions: [
          IconButton(
            tooltip: 'Categorías',
            icon: const Icon(Icons.folder_outlined),
            onPressed: controller.openCategories,
          ),
        ],
      ),
      body: Obx(() {
        final canManage = controller.canManage;
        return ListStateView<ServiceEntity>(
          isLoading: controller.isLoading.value,
          error: controller.loadError.value,
          items: controller.services.toList(),
          onRetry: controller.loadServices,
          loadingMessage: 'Cargando servicios…',
          emptyIcon: Icons.sell_outlined,
          emptyMessage: 'Aún no hay servicios',
          emptySubMessage:
              canManage ? 'Crea el primero para poder agendar citas.' : null,
          emptyActionLabel: canManage ? 'Crear servicio' : null,
          emptyActionIcon: Icons.add,
          onEmptyAction: canManage ? controller.openNewService : null,
          builder: (context, _) => RefreshIndicator(
            onRefresh: controller.refreshFromServer,
            child: _GroupedServices(
              groups: controller.getServicesGroupedByCategory(),
              onTap: canManage ? controller.openEditService : null,
              onActiveChanged:
                  controller.canToggleActive ? controller.setActive : null,
            ),
          ),
        );
      }),
      floatingActionButton: Obx(() => controller.canManage
          ? FloatingActionButton.extended(
              onPressed: controller.openNewService,
              icon: const Icon(Icons.add),
              label: const Text('Servicio'),
            )
          : const SizedBox.shrink()),
    );
  }
}

class _GroupedServices extends StatelessWidget {
  final Map<String, List<ServiceEntity>> groups;
  final ValueChanged<ServiceEntity>? onTap;
  final void Function(ServiceEntity service, bool active)? onActiveChanged;

  const _GroupedServices(
      {required this.groups, required this.onTap, this.onActiveChanged});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final entries = groups.entries.toList();
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(entry.key,
                  style: text.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            ),
            for (final service in entry.value)
              ServiceCard(
                service: service,
                onTap: onTap == null ? null : () => onTap!(service),
                onActiveChanged: onActiveChanged == null
                    ? null
                    : (active) => onActiveChanged!(service, active),
              ),
          ],
        );
      },
    );
  }
}
