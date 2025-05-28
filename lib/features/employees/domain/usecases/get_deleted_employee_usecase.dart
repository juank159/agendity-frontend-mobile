// lib/features/employees/domain/usecases/get_deleted_employees_usecase.dart

import 'package:login_signup/features/employees/domain/entities/employee_entity.dart';
import 'package:login_signup/features/employees/domain/repositories/employees_repository.dart';

class GetDeletedEmployeesUseCase {
  final EmployeesRepository repository;

  GetDeletedEmployeesUseCase(this.repository);

  Future<List<EmployeeEntity>> call() async {
    try {
      print('🗑️ UseCase: Obteniendo empleados eliminados');

      final result = await repository.getDeletedEmployees();

      print('✅ UseCase: ${result.length} empleados eliminados encontrados');
      return result;
    } catch (e) {
      print('❌ UseCase: Error obteniendo empleados eliminados - $e');
      rethrow;
    }
  }
}
