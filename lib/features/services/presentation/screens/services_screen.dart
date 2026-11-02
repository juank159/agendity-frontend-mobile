import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/widgets/app_fade_in.dart';
import 'package:login_signup/core/widgets/app_gradient_button.dart';
import 'package:login_signup/core/widgets/list_state_view.dart';
import 'package:login_signup/shared/widgets/app_section_header.dart';
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
            icon: const Icon(Icons.folder_copy_rounded),
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
          emptyIcon: Icons.spa_rounded,
          emptyMessage: 'Aún no hay servicios',
          emptySubMessage:
              canManage ? 'Crea el primero para poder agendar citas.' : null,
          emptyActionLabel: canManage ? 'Crear servicio' : null,
          emptyActionIcon: Icons.add_rounded,
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
          ? AppGradientButton.fab(
              label: 'Servicio',
              tooltip: 'Agregar servicio',
              onPressed: controller.openNewService,
            )
          : const SizedBox.shrink()),
    );
  }
}

/// Un bloque por categoría: su encabezado (nombre y cuántos servicios) y las
/// tarjetas de sus servicios.
class _GroupedServices extends StatelessWidget {
  final Map<String, List<ServiceEntity>> groups;
  final ValueChanged<ServiceEntity>? onTap;
  final void Function(ServiceEntity service, bool active)? onActiveChanged;

  const _GroupedServices(
      {required this.groups, required this.onTap, this.onActiveChanged});

  @override
  Widget build(BuildContext context) {
    final entries = groups.entries.toList();
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 104),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        final count = entry.value.length;
        return AppFadeIn(
          index: index,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppSectionHeader(
                padding: const EdgeInsets.fromLTRB(0, 18, 0, 10),
                icon: Icons.folder_rounded,
                title: entry.key,
                subtitle: count == 1 ? '1 servicio' : '$count servicios',
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
          ),
        );
      },
    );
  }
}
