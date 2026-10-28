/// Resultado de restaurar un profesional dado de baja. El backend lo deja
/// activo solo si ya verificó su email; si no, queda pendiente de verificación.
class EmployeeRestoration {
  final String employeeId;
  final bool isActive;

  const EmployeeRestoration({required this.employeeId, required this.isActive});

  bool get needsEmailVerification => !isActive;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmployeeRestoration &&
          other.employeeId == employeeId &&
          other.isActive == isActive;

  @override
  int get hashCode => Object.hash(employeeId, isActive);
}
