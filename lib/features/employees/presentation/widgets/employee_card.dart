import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/features/employees/domain/entities/employee_entity.dart';
import 'package:login_signup/features/employees/presentation/controllers/employees_controller.dart';
import 'package:login_signup/shared/widgets/app_avatar.dart';
import 'package:login_signup/shared/widgets/app_card.dart';
import 'package:login_signup/shared/widgets/app_pill.dart';
import 'employee_options_sheet.dart';
import 'employee_status_ui.dart';

/// Tarjeta de un profesional en la lista: avatar, datos, estado, servicios y
/// el distintivo de Propietario. Tocarla abre el detalle; el botón de
/// opciones, las acciones permitidas.
class EmployeeCard extends GetView<EmployeesController> {
  final EmployeeEntity employee;

  const EmployeeCard({super.key, required this.employee});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final serviceCount = employee.serviceIds.length;
    final muted = TextStyle(color: scheme.onSurfaceVariant);

    return AppCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 14, 4, 14),
      depth: 1,
      onTap: () => controller.openDetails(employee),
      semanticLabel: 'Ver a ${employee.fullName}',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppAvatar(
            name: employee.fullName,
            imageUrl: employee.image,
            radius: 26,
            muted: employee.status != EmployeeStatus.active,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  employee.fullName,
                  style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700, color: scheme.onSurface),
                ),
                const SizedBox(height: 2),
                Text(employee.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.merge(muted)),
                if (employee.phone.isNotEmpty)
                  Text(employee.phone,
                      style: theme.textTheme.bodySmall?.merge(muted).tabular),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    EmployeeStatusChip(status: employee.status, dense: true),
                    if (employee.isOwner) const OwnerChip(dense: true),
                    if (serviceCount > 0)
                      AppPill(
                        dense: true,
                        tabular: true,
                        icon: Icons.spa_rounded,
                        label: serviceCount == 1
                            ? '1 servicio'
                            : '$serviceCount servicios',
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
                  icon: const Icon(Icons.more_vert_rounded),
                  tooltip: 'Opciones de ${employee.fullName}',
                  onPressed: () =>
                      EmployeeOptionsSheet.show(context, employee),
                )),
        ],
      ),
    );
  }
}
