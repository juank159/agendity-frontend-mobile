import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/features/employees/domain/entities/employee_entity.dart';
import 'package:login_signup/features/employees/domain/usecases/delete_employee_usecase.dart';
import 'package:login_signup/shared/widgets/app_dialogs.dart';

/// Diálogos propios de la gestión de profesionales. Los simples usan
/// `AppDialogs`; aquí solo los que necesitan algo más (un campo de texto o
/// una acción alternativa).
abstract final class EmployeeDialogs {
  /// Confirma la baja y pide un motivo opcional. `null` = cancelado; `''` =
  /// sin motivo.
  static Future<String?> askDeleteReason(EmployeeEntity employee) =>
      Get.dialog<String>(_DeleteEmployeeDialog(employee: employee));

  /// Activar a mano falló porque el empleado no verificó su email: explica
  /// el motivo y ofrece verificarlo ahora. `true` = verificar.
  static Future<bool> offerEmailVerification(
      EmployeeEntity employee, String reason) async {
    final verify = await Get.dialog<bool>(
      AppDialog(
        tone: AppTone.warning,
        icon: Icons.mark_email_unread_outlined,
        title: 'Falta verificar el email',
        message: reason,
        detail: 'Enviaremos un código a ${employee.email}. Al verificarlo, '
            '${employee.fullName} quedará activo.',
        primaryLabel: 'Verificar email',
        primaryResult: true,
        secondaryLabel: 'Ahora no',
        secondaryResult: false,
      ),
    );
    return verify ?? false;
  }

  /// Confirma la restauración y explica en qué estado queda.
  static Future<bool> confirmRestore(EmployeeEntity employee) =>
      AppDialogs.confirm(
        title: 'Restaurar profesional',
        message: '¿Restaurar a ${employee.fullName}? Volverá a la lista de '
            'profesionales'
            '${employee.isEmailVerified ? '.' : ', pendiente de verificar su email.'}',
        confirmLabel: 'Restaurar',
        icon: Icons.restore,
      );

  /// Confirma activar o desactivar.
  static Future<bool> confirmStatusChange(
      EmployeeEntity employee, bool activate) {
    return AppDialogs.confirm(
      title: activate ? 'Activar profesional' : 'Desactivar profesional',
      message: activate
          ? '${employee.fullName} podrá iniciar sesión y recibir citas.'
          : '${employee.fullName} no podrá iniciar sesión ni recibir citas '
              'nuevas. Sus citas actuales se conservan.',
      confirmLabel: activate ? 'Activar' : 'Desactivar',
      destructive: !activate,
      icon: activate ? Icons.person : Icons.person_off,
    );
  }
}

class _DeleteEmployeeDialog extends StatefulWidget {
  final EmployeeEntity employee;

  const _DeleteEmployeeDialog({required this.employee});

  @override
  State<_DeleteEmployeeDialog> createState() => _DeleteEmployeeDialogState();
}

class _DeleteEmployeeDialogState extends State<_DeleteEmployeeDialog> {
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.tokens.error;
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.container,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.delete_outline,
                      color: colors.color, size: 40),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Eliminar profesional',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '¿Eliminar a ${widget.employee.fullName}? Se conserva su '
                'historial de citas y se puede restaurar después.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _reason,
                maxLines: 2,
                maxLength: DeleteEmployeeUseCase.maxReasonLength,
                decoration: const InputDecoration(
                  labelText: 'Motivo (opcional)',
                  hintText: 'Ej.: renuncia, fin de contrato…',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: scheme.error,
                  foregroundColor: scheme.onError,
                ),
                onPressed: () =>
                    Navigator.of(context).pop(_reason.text.trim()),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 6),
                  child: Text('Eliminar'),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
