import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/features/employees/domain/entities/employee_restoration.dart';
import 'package:login_signup/features/employees/domain/failures/employee_failures.dart';
import 'package:login_signup/features/employees/domain/repositories/employees_repository.dart';

/// Restaura un empleado dado de baja. Queda activo solo si ya verificó su
/// email (`EmployeeRestoration.needsEmailVerification`).
class RestoreEmployeeUseCase extends UseCase<EmployeeRestoration, String> {
  final EmployeesRepository repository;

  RestoreEmployeeUseCase(this.repository);

  @override
  Future<Either<Failure, EmployeeRestoration>> call(String params) async {
    if (params.trim().isEmpty) {
      return const Left(InvalidEmployeeDataFailure(
          message: 'Falta el profesional a restaurar'));
    }
    return repository.restoreEmployee(params.trim());
  }
}
