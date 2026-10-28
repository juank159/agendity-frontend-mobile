import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/features/employees/domain/failures/employee_failures.dart';
import 'package:login_signup/features/employees/domain/repositories/employees_repository.dart';

class ToggleEmployeeStatusParams {
  final String employeeId;
  final bool isActive;

  const ToggleEmployeeStatusParams({
    required this.employeeId,
    required this.isActive,
  });
}

/// Activa o desactiva un empleado. Activar uno que no ha verificado su email
/// → `EmployeeEmailNotVerifiedFailure` (lo decide el backend, 2.15).
class ToggleEmployeeStatusUseCase
    extends UseCase<Unit, ToggleEmployeeStatusParams> {
  final EmployeesRepository repository;

  ToggleEmployeeStatusUseCase(this.repository);

  @override
  Future<Either<Failure, Unit>> call(ToggleEmployeeStatusParams params) async {
    if (params.employeeId.trim().isEmpty) {
      return const Left(
          InvalidEmployeeDataFailure(message: 'Falta el profesional'));
    }
    return repository.setEmployeeActive(
        params.employeeId.trim(), params.isActive);
  }
}
