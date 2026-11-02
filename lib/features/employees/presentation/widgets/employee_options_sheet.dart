import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/core/utils/formatters.dart';
import 'package:login_signup/features/employees/domain/entities/employee_entity.dart';
import 'package:login_signup/features/employees/presentation/controllers/employees_controller.dart';
import 'package:login_signup/shared/widgets/app_sheet.dart';
import 'employee_status_ui.dart';

/// Opciones de un profesional. Solo muestra lo permitido por
/// `EmployeesController` (`canEdit`, `canChangeStatus`, `canDelete`,
/// `canRestore`, `canVerifyEmail`): el Owner no se edita, desactiva ni borra.
class EmployeeOptionsSheet extends GetView<EmployeesController> {
  final EmployeeEntity employee;

  const EmployeeOptionsSheet({super.key, required this.employee});

  /// Abre la hoja de la guía (`AppSheet`) con el nombre del profesional.
  static Future<void> show(BuildContext context, EmployeeEntity employee) =>
      AppSheet.show<void>(
        context,
        title: employee.fullName,
        icon: Icons.manage_accounts_rounded,
        builder: (_) => EmployeeOptionsSheet(employee: employee),
      );

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final scheme = Theme.of(context).colorScheme;
    final status = employee.status;

    /// Cierra la hoja y después ejecuta la acción (que puede abrir diálogos).
    VoidCallback run(Future<Object?> Function() action) => () {
          Navigator.of(context).pop();
          action();
        };

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                EmployeeStatusChip(status: status),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(status.description,
                      style: TextStyle(color: scheme.onSurfaceVariant)),
                ),
              ],
            ),
          ),
          _Option(
            icon: Icons.visibility_rounded,
            label: 'Ver detalles',
            onTap: run(() => controller.openDetails(employee)),
          ),
          if (controller.canEdit(employee))
            _Option(
              icon: Icons.edit_rounded,
              label: 'Editar',
              onTap: run(() => controller.openEdit(employee)),
            ),
          if (controller.canVerifyEmail(employee))
            _Option(
              icon: Icons.mark_email_read_rounded,
              label: 'Verificar email',
              subtitle: 'Enviar un código a ${employee.email}',
              color: tokens.info.color,
              onTap: run(() => controller.verifyEmail(employee)),
            ),
          if (controller.canChangeStatus(employee))
            employee.isActive
                ? _Option(
                    icon: Icons.person_off_rounded,
                    label: 'Desactivar',
                    subtitle: 'No podrá iniciar sesión ni recibir citas',
                    color: tokens.warning.color,
                    onTap: run(() => controller.setActive(employee, false)),
                  )
                : _Option(
                    icon: Icons.person_rounded,
                    label: 'Activar',
                    subtitle: employee.isEmailVerified
                        ? 'Podrá iniciar sesión y recibir citas'
                        : 'Requiere el email verificado',
                    color: tokens.success.color,
                    onTap: run(() => controller.setActive(employee, true)),
                  ),
          if (controller.canDelete(employee))
            _Option(
              icon: Icons.delete_rounded,
              label: 'Eliminar',
              subtitle: 'Se conserva su historial y se puede restaurar',
              color: scheme.error,
              onTap: run(() => controller.delete(employee)),
            ),
          if (controller.canRestore(employee))
            _Option(
              icon: Icons.restore_rounded,
              label: 'Restaurar',
              color: tokens.success.color,
              onTap: run(() => controller.restore(employee)),
            ),
          if (employee.isDeleted) ...[
            if (employee.deletedAt != null)
              _Info(
                icon: Icons.event_busy_rounded,
                label: 'Eliminado el ${formatDate(employee.deletedAt!)}',
              ),
            _Info(
              icon: Icons.notes_rounded,
              label: 'Motivo: ${employee.deletionReason ?? 'sin motivo'}',
            ),
          ],
          if (employee.isOwner)
            const _Info(
              icon: Icons.workspace_premium_rounded,
              label: 'Eres el propietario: tu cuenta no se puede '
                  'desactivar ni eliminar desde aquí.',
            ),
        ],
      ),
    );
  }
}

class _Option extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Color? color;
  final VoidCallback onTap;

  const _Option({
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tint = color ?? scheme.primary;
    return ListTile(
      shape: const RoundedRectangleBorder(borderRadius: AppRadii.fieldRadius),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: tint.withValues(alpha: 0.12),
          borderRadius: AppRadii.chipRadius,
        ),
        child: Icon(icon, color: tint),
      ),
      title: Text(label,
          style: TextStyle(
              color: color ?? scheme.onSurface, fontWeight: FontWeight.w600)),
      subtitle: subtitle == null ? null : Text(subtitle!),
      onTap: onTap,
    );
  }
}

class _Info extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Info({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return ListTile(
      dense: true,
      leading: Icon(icon, color: color),
      title: Text(label, style: TextStyle(color: color)),
    );
  }
}
