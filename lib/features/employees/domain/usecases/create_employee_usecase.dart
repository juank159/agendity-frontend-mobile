import 'package:login_signup/features/employees/domain/entities/employee_entity.dart';
import 'package:login_signup/features/employees/domain/repositories/employees_repository.dart';

class CreateEmployeeUseCase {
  final EmployeesRepository repository;

  CreateEmployeeUseCase(this.repository);

  Future<EmployeeEntity> call(EmployeeEntity employee, String password) {
    return repository.createEmployee(employee, password);
  }
}
