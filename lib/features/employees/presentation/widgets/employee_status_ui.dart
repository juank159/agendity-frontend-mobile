import 'package:flutter/material.dart';
import 'package:login_signup/features/employees/domain/entities/employee_entity.dart';

/// Texto, color e icono de `EmployeeStatus` (la entidad no conoce Flutter).
/// Los colores fijos son los de antes de la 4.07; FP los pasa a `AppTokens`.
extension EmployeeStatusUi on EmployeeStatus {
  String get label => switch (this) {
        EmployeeStatus.active => 'Activo',
        EmployeeStatus.pendingVerification => 'Pendiente de verificación',
        EmployeeStatus.inactive => 'Inactivo',
        EmployeeStatus.deleted => 'Eliminado',
      };

  Color get color => switch (this) {
        EmployeeStatus.active => Colors.green,
        EmployeeStatus.pendingVerification => Colors.amber.shade800,
        EmployeeStatus.inactive => Colors.orange,
        EmployeeStatus.deleted => Colors.red,
      };

  IconData get icon => switch (this) {
        EmployeeStatus.active => Icons.check_circle,
        EmployeeStatus.pendingVerification => Icons.mark_email_unread_outlined,
        EmployeeStatus.inactive => Icons.pause_circle,
        EmployeeStatus.deleted => Icons.delete_forever,
      };
}
