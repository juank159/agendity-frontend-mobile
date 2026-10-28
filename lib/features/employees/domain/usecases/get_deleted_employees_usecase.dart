import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/features/employees/domain/entities/employee_entity.dart';
import 'package:login_signup/features/employees/domain/repositories/employees_repository.dart';

/// Empleados dados de baja (soft-delete), para restaurarlos.
class GetDeletedEmployeesUseCase
    extends UseCase<List<EmployeeEntity>, NoParams> {
  final EmployeesRepository repository;

  GetDeletedEmployeesUseCase(this.repository);

  @override
  Future<Either<Failure, List<EmployeeEntity>>> call(NoParams params) =>
      repository.getDeletedEmployees();
}
