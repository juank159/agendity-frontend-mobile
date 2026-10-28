import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/features/employees/domain/entities/employee_entity.dart';
import 'package:login_signup/features/employees/presentation/controllers/employees_controller.dart';
import 'employee_avatar.dart';
import 'employee_options_sheet.dart';
import 'employee_status_ui.dart';

/// Tarjeta de un profesional en la lista: datos, estado, servicios y el
/// distintivo de Propietario. Tocarla abre el detalle; el botón de opciones,
/// las acciones permitidas.
class EmployeeCard extends GetView<EmployeesController> {
  final EmployeeEntity employee;

  const EmployeeCard({super.key, required this.employee});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final serviceCount = employee.serviceIds.length;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => controller.openDetails(employee),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EmployeeAvatar(employee: employee),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      employee.fullName,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 17),
                    ),
                    const SizedBox(height: 4),
                    Text(employee.email,
                        style: TextStyle(color: scheme.onSurfaceVariant)),
                    if (employee.phone.isNotEmpty)
                      Text(employee.phone,
                          style: TextStyle(color: scheme.onSurfaceVariant)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        EmployeeStatusChip(status: employee.status),
                        if (employee.isOwner) const OwnerChip(),
                        if (serviceCount > 0)
                          Chip(
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            avatar: const Icon(Icons.spa, size: 16),
                            label: Text(serviceCount == 1
                                ? '1 servicio'
                                : '$serviceCount servicios'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Obx(() => controller.isBusy(employee)
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox.square(
                        dimension: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : IconButton(
                      icon: const Icon(Icons.more_vert),
                      tooltip: 'Opciones de ${employee.fullName}',
                      onPressed: () =>
                          EmployeeOptionsSheet.show(context, employee),
                    )),
            ],
          ),
        ),
      ),
    );
  }
}
