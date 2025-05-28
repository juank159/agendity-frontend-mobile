abstract class Failure {
  final String message;

  Failure({required this.message});

  @override
  String toString() {
    return message;
  }
}

class ServerFailure extends Failure {
  ServerFailure({required super.message});
}

class CacheFailure extends Failure {
  CacheFailure({required super.message});
}

class StorageFailure extends Failure {
  StorageFailure({required super.message});
}

class NetworkFailure extends Failure {
  NetworkFailure({super.message = 'Error de conexión a internet'});
}

class NotFoundFailure extends Failure {
  NotFoundFailure({super.message = 'Recurso no encontrado'});
}

// =============================================================================
// ERRORES ESPECÍFICOS DE EMPLEADOS
// =============================================================================

/// Error específico para email duplicado
class DuplicateEmailFailure extends ServerFailure {
  final String email;

  DuplicateEmailFailure({
    required this.email,
    String? message,
  }) : super(message: message ?? 'Ya existe un usuario con el email: $email');
}

/// Error específico para teléfono duplicado
class DuplicatePhoneFailure extends ServerFailure {
  final String phone;

  DuplicatePhoneFailure({
    required this.phone,
    String? message,
  }) : super(
            message: message ?? 'Ya existe un usuario con el teléfono: $phone');
}

/// Error cuando se intenta eliminar al dueño del negocio
class OwnerDeletionFailure extends ServerFailure {
  OwnerDeletionFailure({
    String? message,
  }) : super(
          message: message ?? 'No se puede eliminar al dueño del negocio',
        );
}

// 🆕 NUEVO: Error cuando el empleado ya está eliminado
class AlreadyDeletedFailure extends ServerFailure {
  final String employeeId;

  AlreadyDeletedFailure({
    required this.employeeId,
    String? message,
  }) : super(
          message: message ?? 'El empleado ya ha sido eliminado previamente',
        );
}

// 🆕 NUEVO: Error cuando no se puede restaurar
class RestoreFailure extends ServerFailure {
  final String? employeeId;

  RestoreFailure({
    this.employeeId,
    String? message,
  }) : super(
          message: message ?? 'No se pudo restaurar el empleado',
        );
}

// 🆕 NUEVO: Error cuando el empleado no está eliminado (para restaurar)
class NotDeletedFailure extends ServerFailure {
  final String employeeId;

  NotDeletedFailure({
    required this.employeeId,
    String? message,
  }) : super(
          message: message ?? 'El empleado no está eliminado',
        );
}
