import 'package:flutter/material.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/features/employees/domain/entities/employee_entity.dart';

/// Texto, tono e icono de `EmployeeStatus` (la entidad no conoce Flutter).
/// Los colores salen de `AppTokens` (modo oscuro incluido).
extension EmployeeStatusUi on EmployeeStatus {
  String get label => switch (this) {
        EmployeeStatus.active => 'Activo',
        EmployeeStatus.pendingVerification => 'Pendiente de verificación',
        EmployeeStatus.inactive => 'Inactivo',
        EmployeeStatus.deleted => 'Eliminado',
      };

  /// Qué significa el estado para el negocio.
  String get description => switch (this) {
        EmployeeStatus.active => 'Puede iniciar sesión y recibir citas.',
        EmployeeStatus.pendingVerification =>
          'Debe verificar su email para activarse. Mientras tanto no puede '
              'iniciar sesión ni recibir citas.',
        EmployeeStatus.inactive =>
          'Desactivado: no puede iniciar sesión ni recibir citas.',
        EmployeeStatus.deleted =>
          'Dado de baja. Conserva su historial y se puede restaurar.',
      };

  AppTone get tone => switch (this) {
        EmployeeStatus.active => AppTone.success,
        EmployeeStatus.pendingVerification => AppTone.info,
        EmployeeStatus.inactive => AppTone.warning,
        EmployeeStatus.deleted => AppTone.error,
      };

  IconData get icon => switch (this) {
        EmployeeStatus.active => Icons.check_circle,
        EmployeeStatus.pendingVerification => Icons.mark_email_unread_outlined,
        EmployeeStatus.inactive => Icons.pause_circle,
        EmployeeStatus.deleted => Icons.delete_forever,
      };

  ToneColors colorsOf(BuildContext context) => context.tokens.tone(tone);
}

/// Chip con el estado de un profesional.
class EmployeeStatusChip extends StatelessWidget {
  final EmployeeStatus status;

  const EmployeeStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final colors = status.colorsOf(context);
    return Semantics(
      label: 'Estado: ${status.label}',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: colors.container,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: colors.color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(status.icon, size: 14, color: colors.color),
            const SizedBox(width: 4),
            Text(
              status.label,
              style: TextStyle(
                color: colors.onContainer,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Chip de "Propietario" para el Owner en la lista de profesionales.
class OwnerChip extends StatelessWidget {
  const OwnerChip({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.business_center,
              size: 14, color: scheme.onTertiaryContainer),
          const SizedBox(width: 4),
          Text(
            'Propietario',
            style: TextStyle(
              color: scheme.onTertiaryContainer,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
