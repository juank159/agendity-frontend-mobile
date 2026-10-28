import 'package:dartz/dartz.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/features/employees/domain/entities/employee_entity.dart';
import 'package:login_signup/features/employees/domain/failures/employee_failures.dart';
import 'package:login_signup/features/employees/domain/repositories/employees_repository.dart';

/// Un profesional del negocio por id (con servicios y horario).
class GetEmployeeByIdUseCase extends UseCase<EmployeeEntity, String> {
  final EmployeesRepository repository;

  GetEmployeeByIdUseCase(this.repository);

  @override
  Future<Either<Failure, EmployeeEntity>> call(String params) async {
    if (params.trim().isEmpty) {
      return const Left(
          InvalidEmployeeDataFailure(message: 'Falta el profesional'));
    }
    return repository.getEmployeeById(params.trim());
  }
}
