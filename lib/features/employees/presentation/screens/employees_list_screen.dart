import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/widgets/empty_state.dart';
import 'package:login_signup/core/widgets/list_state_view.dart';
import 'package:login_signup/features/employees/presentation/controllers/employees_controller.dart';
import 'package:login_signup/features/employees/presentation/widgets/employee_card.dart';

/// Profesionales del negocio (solo Owner): activos, inactivos y pendientes
/// de verificación, y en otra vista los dados de baja.
class EmployeesListScreen extends GetView<EmployeesController> {
  const EmployeesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profesionales'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
            onPressed: controller.refreshCurrent,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Obx(() => SegmentedButton<bool>(
                  segments: [
                    ButtonSegment(
                      value: false,
                      icon: const Icon(Icons.people_outline),
                      label: Text('Equipo (${controller.employees.length})'),
                    ),
                    const ButtonSegment(
                      value: true,
                      icon: Icon(Icons.delete_outline),
                      label: Text('Eliminados'),
                    ),
                  ],
                  selected: {controller.showDeleted.value},
                  onSelectionChanged: (s) => controller.showDeletedView(s.first),
                )),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: controller.searchController,
              onChanged: (v) => controller.searchQuery.value = v,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre, email o teléfono',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: Obx(() => controller.searchQuery.value.isEmpty
                    ? const SizedBox.shrink()
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        tooltip: 'Limpiar búsqueda',
                        onPressed: controller.clearSearch,
                      )),
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          const Expanded(child: _EmployeesList()),
        ],
      ),
      floatingActionButton: Obx(() => controller.showDeleted.value
          ? const SizedBox.shrink()
          : FloatingActionButton(
              tooltip: 'Agregar profesional',
              onPressed: controller.openCreate,
              child: const Icon(Icons.person_add_alt_1),
            )),
    );
  }
}

class _EmployeesList extends GetView<EmployeesController> {
  const _EmployeesList();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final deletedView = controller.showDeleted.value;
      final source =
          deletedView ? controller.deletedEmployees : controller.employees;
      final visible = controller.visibleEmployees;
      final query = controller.searchQuery.value.trim();

      return ListStateView(
        isLoading: controller.isLoadingCurrent,
        error: controller.currentError,
        items: source.toList(),
        onRetry: controller.refreshCurrent,
        loadingMessage: 'Cargando profesionales…',
        emptyIcon: deletedView ? Icons.restore_from_trash : Icons.people_outline,
        emptyMessage: deletedView
            ? 'No hay profesionales eliminados'
            : 'Aún no tienes profesionales',
        emptySubMessage: deletedView
            ? 'Los profesionales que elimines aparecerán aquí y podrás '
                'restaurarlos.'
            : 'Agrega a tu equipo para asignarle citas.',
        emptyActionLabel: deletedView ? null : 'Agregar profesional',
        emptyActionIcon: Icons.person_add_alt_1,
        onEmptyAction: deletedView ? null : controller.openCreate,
        builder: (context, _) {
          if (visible.isEmpty) {
            return EmptyState(
              icon: Icons.search_off,
              message: 'Sin resultados para "$query"',
              actionLabel: 'Limpiar búsqueda',
              onAction: controller.clearSearch,
            );
          }
          return RefreshIndicator(
            onRefresh: controller.refreshFromServer,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
              itemCount: visible.length,
              itemBuilder: (_, i) => EmployeeCard(employee: visible[i]),
            ),
          );
        },
      );
    });
  }
}
