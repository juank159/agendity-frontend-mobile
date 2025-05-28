// lib/features/employees/domain/usecases/restore_employee_usecase.dart

import 'package:login_signup/features/employees/domain/repositories/employees_repository.dart';

class RestoreEmployeeUseCase {
  final EmployeesRepository repository;

  RestoreEmployeeUseCase(this.repository);

  Future<bool> call(String id) async {
    try {
      print('♻️ UseCase: Iniciando restauración de empleado $id');

      final result = await repository.restoreEmployee(id);

      print('✅ UseCase: Restauración completada');
      return result;
    } catch (e) {
      print('❌ UseCase: Error restaurando empleado - $e');
      rethrow;
    }
  }
}
