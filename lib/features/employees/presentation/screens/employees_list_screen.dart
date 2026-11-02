import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/widgets/app_fade_in.dart';
import 'package:login_signup/core/widgets/app_gradient_button.dart';
import 'package:login_signup/core/widgets/empty_state.dart';
import 'package:login_signup/core/widgets/list_state_view.dart';
import 'package:login_signup/features/employees/presentation/controllers/employees_controller.dart';
import 'package:login_signup/features/employees/presentation/widgets/employee_card.dart';
import 'package:login_signup/shared/widgets/app_search_field.dart';

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
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Actualizar',
            onPressed: controller.refreshCurrent,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: SizedBox(
              width: double.infinity,
              child: Obx(() => SegmentedButton<bool>(
                    segments: [
                      ButtonSegment(
                        value: false,
                        icon: const Icon(Icons.groups_rounded),
                        label: Text('Equipo (${controller.employees.length})'),
                      ),
                      const ButtonSegment(
                        value: true,
                        icon: Icon(Icons.restore_from_trash_rounded),
                        label: Text('Eliminados'),
                      ),
                    ],
                    selected: {controller.showDeleted.value},
                    onSelectionChanged: (s) =>
                        controller.showDeletedView(s.first),
                  )),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: AppSearchField(
              controller: controller.searchController,
              hint: 'Buscar por nombre, email o teléfono',
              clearTooltip: 'Limpiar búsqueda',
              onChanged: (v) => controller.searchQuery.value = v,
              onClear: controller.clearSearch,
            ),
          ),
          const Expanded(child: _EmployeesList()),
        ],
      ),
      floatingActionButton: Obx(() => controller.showDeleted.value
          ? const SizedBox.shrink()
          : AppGradientButton.fab(
              label: 'Profesional',
              icon: Icons.person_add_alt_1_rounded,
              tooltip: 'Agregar profesional',
              onPressed: controller.openCreate,
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
        emptyIcon:
            deletedView ? Icons.restore_from_trash_rounded : Icons.groups_rounded,
        emptyMessage: deletedView
            ? 'No hay profesionales eliminados'
            : 'Aún no tienes profesionales',
        emptySubMessage: deletedView
            ? 'Los profesionales que elimines aparecerán aquí y podrás '
                'restaurarlos.'
            : 'Agrega a tu equipo para asignarle citas.',
        emptyActionLabel: deletedView ? null : 'Agregar profesional',
        emptyActionIcon: Icons.person_add_alt_1_rounded,
        onEmptyAction: deletedView ? null : controller.openCreate,
        builder: (context, _) {
          if (visible.isEmpty) {
            return EmptyState(
              icon: Icons.search_off_rounded,
              message: 'Sin resultados para "$query"',
              actionLabel: 'Limpiar búsqueda',
              onAction: controller.clearSearch,
            );
          }
          return RefreshIndicator(
            onRefresh: controller.refreshFromServer,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 104),
              itemCount: visible.length,
              itemBuilder: (_, i) => AppFadeIn(
                index: i,
                child: EmployeeCard(employee: visible[i]),
              ),
            ),
          );
        },
      );
    });
  }
}
