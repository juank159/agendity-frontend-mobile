import 'package:flutter/material.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/features/employees/domain/entities/employee_entity.dart';
import 'package:login_signup/shared/widgets/app_pill.dart';
import 'package:login_signup/shared/widgets/status_chip.dart';

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
        EmployeeStatus.active => Icons.check_circle_rounded,
        EmployeeStatus.pendingVerification => Icons.mark_email_unread_rounded,
        EmployeeStatus.inactive => Icons.pause_circle_rounded,
        EmployeeStatus.deleted => Icons.delete_forever_rounded,
      };

  ToneColors colorsOf(BuildContext context) => context.tokens.tone(tone);
}

/// Chip con el estado de un profesional (el `StatusChip` de la guía con el
/// tono, el ícono y el texto del estado).
class EmployeeStatusChip extends StatelessWidget {
  final EmployeeStatus status;
  final bool dense;

  const EmployeeStatusChip(
      {super.key, required this.status, this.dense = false});

  @override
  Widget build(BuildContext context) => StatusChip(
        label: status.label,
        icon: status.icon,
        colors: status.colorsOf(context),
        dense: dense,
      );
}

/// Píldora de "Propietario" para el Owner en la lista de profesionales.
class OwnerChip extends StatelessWidget {
  final bool dense;

  const OwnerChip({super.key, this.dense = false});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppPill(
      label: 'Propietario',
      icon: Icons.workspace_premium_rounded,
      dense: dense,
      colors: ToneColors(
        color: scheme.tertiary,
        container: scheme.tertiaryContainer,
        onContainer: scheme.onTertiaryContainer,
      ),
    );
  }
}
