import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/features/employees/domain/entities/employee_entity.dart';
import 'package:login_signup/features/employees/domain/repositories/employees_repository.dart';

/// El Owner y sus empleados sin baja (activos, inactivos y pendientes de
/// verificación). Para agendar, filtrar con `EmployeeEntity.canBeScheduled`.
class GetEmployeesUseCase extends UseCase<List<EmployeeEntity>, NoParams> {
  final EmployeesRepository repository;

  GetEmployeesUseCase(this.repository);

  @override
  Future<Either<Failure, List<EmployeeEntity>>> call(NoParams params) =>
      repository.getEmployees();
}
