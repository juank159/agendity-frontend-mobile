import 'package:login_signup/features/employees/domain/entities/employee_entity.dart';
import 'package:login_signup/features/employees/domain/repositories/employees_repository.dart';

class GetEmployeesUseCase {
  final EmployeesRepository repository;

  GetEmployeesUseCase(this.repository);

  Future<List<EmployeeEntity>> call() async {
    return await repository.getEmployees();
  }
}
