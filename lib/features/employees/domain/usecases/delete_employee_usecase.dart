import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/features/employees/domain/failures/employee_failures.dart';
import 'package:login_signup/features/employees/domain/repositories/employees_repository.dart';

class DeleteEmployeeParams {
  final String employeeId;

  /// Motivo opcional; vacío = sin motivo (el backend pone "Eliminado por
  /// administrador").
  final String? reason;

  const DeleteEmployeeParams({required this.employeeId, this.reason});
}

/// Da de baja a un empleado (soft-delete): queda inactivo, conserva su
/// historial y se puede restaurar. El Owner no aparece como borrable: el
/// backend responde 404 si se intenta.
class DeleteEmployeeUseCase extends UseCase<Unit, DeleteEmployeeParams> {
  static const maxReasonLength = 255;

  final EmployeesRepository repository;

  DeleteEmployeeUseCase(this.repository);

  @override
  Future<Either<Failure, Unit>> call(DeleteEmployeeParams params) async {
    if (params.employeeId.trim().isEmpty) {
      return const Left(InvalidEmployeeDataFailure(
          message: 'Falta el profesional a eliminar'));
    }
    final reason = params.reason?.trim();
    if (reason != null && reason.length > maxReasonLength) {
      return const Left(InvalidEmployeeDataFailure(
          message: 'El motivo no puede pasar de $maxReasonLength caracteres'));
    }
    return repository.deleteEmployee(params.employeeId.trim(),
        reason: reason == null || reason.isEmpty ? null : reason);
  }
}
