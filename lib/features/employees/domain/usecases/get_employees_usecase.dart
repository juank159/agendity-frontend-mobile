// import 'package:login_signup/features/employees/domain/entities/employee_entity.dart';
// import 'package:login_signup/features/employees/domain/repositories/employees_repository.dart';

// class GetEmployeesUseCase {
//   final EmployeesRepository repository;

//   GetEmployeesUseCase(this.repository);

//   Future<List<EmployeeEntity>> call() async {
//     return await repository.getEmployees();
//   }
// }

// lib/features/employees/domain/usecases/get_employees_usecase.dart

import 'package:login_signup/features/employees/domain/entities/employee_entity.dart';
import 'package:login_signup/features/employees/domain/repositories/employees_repository.dart';

class GetEmployeesUseCase {
  final EmployeesRepository repository;

  GetEmployeesUseCase(this.repository);

  // 🔄 MODIFICADO: Método principal (solo empleados activos)
  Future<List<EmployeeEntity>> call() async {
    try {
      print('📋 UseCase: Obteniendo empleados activos');

      final result = await repository.getEmployees();

      print('✅ UseCase: ${result.length} empleados activos encontrados');
      return result;
    } catch (e) {
      print('❌ UseCase: Error obteniendo empleados - $e');
      rethrow;
    }
  }

  // 🆕 NUEVO: Método para obtener todos (incluyendo eliminados si se especifica)
  Future<List<EmployeeEntity>> getAllEmployees(
      {bool includeDeleted = false}) async {
    try {
      print(
          '📋 UseCase: Obteniendo todos los empleados, incluir eliminados: $includeDeleted');

      final result =
          await repository.getAllEmployees(includeDeleted: includeDeleted);

      print('✅ UseCase: ${result.length} empleados encontrados');
      return result;
    } catch (e) {
      print('❌ UseCase: Error obteniendo todos los empleados - $e');
      rethrow;
    }
  }

  // 🆕 NUEVO: Método para obtener solo empleados activos
  Future<List<EmployeeEntity>> getActiveEmployees() async {
    try {
      print('📋 UseCase: Obteniendo solo empleados activos');

      final result = await repository.getActiveEmployees();

      print('✅ UseCase: ${result.length} empleados activos encontrados');
      return result;
    } catch (e) {
      print('❌ UseCase: Error obteniendo empleados activos - $e');
      rethrow;
    }
  }
}
