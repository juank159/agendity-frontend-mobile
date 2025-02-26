import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/constants/app_colors.dart';
import 'package:login_signup/features/employees/presentation/controllers/employees_controller.dart';
import 'package:login_signup/features/services/domain/entities/service_entity.dart';
import 'package:login_signup/features/services/presentation/controller/services_controller.dart';

class EmployeeServicesSection extends StatelessWidget {
  final EmployeesController employeesController;
  final ServicesController servicesController;

  const EmployeeServicesSection({
    Key? key,
    required this.employeesController,
    required this.servicesController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ServicesController>(
      builder: (controller) {
        // Cargar servicios si están vacíos
        if (controller.services.isEmpty) {
          // Sólo mostrar loader si está cargando
          if (controller.isLoading.value) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else {
            // Intentar cargar servicios de forma manual
            WidgetsBinding.instance.addPostFrameCallback((_) {
              controller.loadServices();
            });
            return const Center(
              child: Column(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Cargando servicios...',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            );
          }
        }

        // Mostrar los servicios agrupados
        final groupedServices = controller.getServicesGroupedByCategory();
        if (groupedServices.isEmpty) {
          return const Center(
            child: Column(
              children: [
                Icon(Icons.warning, size: 48, color: Colors.orange),
                SizedBox(height: 16),
                Text(
                  'No hay servicios disponibles',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          );
        }

        return Column(
          children: groupedServices.entries.map((entry) {
            return _buildCategoryServicesList(
              categoryName: entry.key,
              services: entry.value,
              selectedIds: employeesController.selectedServiceIds,
              onToggle: employeesController.toggleServiceSelection,
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildServiceCheckbox({
    required ServiceEntity serviceEntity,
    required RxList<String> selectedIds,
    required Function(String) onToggle,
  }) {
    return Obx(() {
      final isSelected = selectedIds.contains(serviceEntity.id ?? '');
      return CheckboxListTile(
        title: Text(serviceEntity.name),
        subtitle: Row(
          children: [
            Text(
              '\$${serviceEntity.price}',
              style: TextStyle(
                color: Colors.green[700],
                fontWeight: FontWeight.bold,
              ),
            ),
            if (isSelected)
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Icon(
                  Icons.check_circle,
                  color: Colors.green[700],
                  size: 16,
                ),
              ),
          ],
        ),
        value: isSelected,
        onChanged: (_) => onToggle(serviceEntity.id ?? ''),
        activeColor: AppColors.primary,
        dense: true,
        contentPadding: EdgeInsets.zero,
        // Añadir un indicador visual adicional
        secondary: isSelected
            ? const Icon(Icons.check_circle, color: AppColors.primary)
            : null,
      );
    });
  }

  Widget _buildCategoryServicesList({
    required String categoryName,
    required List<dynamic> services,
    required RxList<String> selectedIds,
    required Function(String) onToggle,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              categoryName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...services.map((service) {
              final ServiceEntity serviceEntity = service as ServiceEntity;
              return GetBuilder<EmployeesController>(
                builder: (controller) {
                  return CheckboxListTile(
                    title: Text(serviceEntity.name),
                    subtitle: Text(
                      '\$${serviceEntity.price}',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    value: controller.selectedServiceIds
                        .contains(serviceEntity.id ?? ''),
                    onChanged: (_) => onToggle(serviceEntity.id ?? ''),
                    activeColor: AppColors.primary,
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  );
                },
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
