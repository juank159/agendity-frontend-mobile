import 'package:login_signup/features/employees/data/datasources/employees_remote_datasource.dart';
import 'package:login_signup/features/employees/domain/entities/employee_entity.dart';
import 'package:login_signup/features/employees/domain/entities/service_assignment.dart';
import 'package:login_signup/features/employees/domain/repositories/employees_repository.dart';
import 'package:login_signup/core/errors/failures.dart';

class EmployeesRepositoryImpl implements EmployeesRepository {
  final EmployeesRemoteDataSource remoteDataSource;

  EmployeesRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<EmployeeEntity>> getEmployees() async {
    try {
      print('🏛️ Repository: Obteniendo empleados (solo activos)');
      return await remoteDataSource.getEmployees();
    } catch (e) {
      print('❌ Repository.getEmployees: $e');

      if (e is Failure) {
        rethrow;
      }

      throw ServerFailure(
          message: 'Error al cargar la lista de empleados: ${e.toString()}');
    }
  }

  @override
  Future<EmployeeEntity> getEmployeeById(String id) async {
    try {
      print('🏛️ Repository: Obteniendo empleado por ID: $id');
      return await remoteDataSource.getEmployeeById(id);
    } catch (e) {
      print('❌ Repository.getEmployeeById: $e');

      if (e is Failure) {
        rethrow;
      }

      throw ServerFailure(
          message: 'Error al obtener los datos del empleado: ${e.toString()}');
    }
  }

  @override
  Future<EmployeeEntity> createEmployee(
      EmployeeEntity employee, String password) async {
    try {
      print('🏛️ Repository: Creando empleado: ${employee.fullName}');
      return await remoteDataSource.createEmployee(employee, password);
    } catch (e) {
      print('❌ Repository.createEmployee: $e');
      rethrow; // Propagar error sin modificar
    }
  }

  @override
  Future<EmployeeEntity> updateEmployee(
    String id,
    EmployeeEntity employee, {
    String? password,
    Map<String, ServiceAssignment>? serviceAssignments,
  }) async {
    try {
      print('🏛️ Repository: Actualizando empleado: $id');
      return await remoteDataSource.updateEmployee(
        id,
        employee,
        password: password,
        serviceAssignments: serviceAssignments,
      );
    } catch (e) {
      print('❌ Repository.updateEmployee: $e');

      if (e is Failure) {
        rethrow;
      }

      throw ServerFailure(
          message: 'Error al actualizar el empleado: ${e.toString()}');
    }
  }

  @override
  Future<EmployeeEntity> toggleEmployeeStatus(String id, bool isActive) async {
    try {
      print('🏛️ Repository: Cambiando estado de empleado $id a: $isActive');
      return await remoteDataSource.toggleEmployeeStatus(id, isActive);
    } catch (e) {
      print('❌ Repository.toggleEmployeeStatus: $e');

      if (e is Failure) {
        rethrow;
      }

      throw ServerFailure(
          message: 'Error al cambiar el estado del empleado: ${e.toString()}');
    }
  }

  @override
  Future<bool> verifyEmployeeEmail(String employeeId, String code) async {
    try {
      print('🏛️ Repository: Verificando email de empleado: $employeeId');
      return await remoteDataSource.verifyEmployeeEmail(employeeId, code);
    } catch (e) {
      print('❌ Repository.verifyEmployeeEmail: $e');

      if (e is Failure) {
        rethrow;
      }

      throw ServerFailure(
          message: 'Error al verificar el email del empleado: ${e.toString()}');
    }
  }

  // 🔄 MODIFICADO: deleteEmployee ahora acepta razón opcional
  @override
  Future<bool> deleteEmployee(String id, {String? reason}) async {
    try {
      print('🏛️ Repository: Iniciando eliminación de empleado: $id');
      if (reason != null && reason.isNotEmpty) {
        print('🏛️ Repository: Razón: $reason');
      }

      return await remoteDataSource.deleteEmployee(id, reason: reason);
    } catch (e) {
      print(
          '❌ Repository.deleteEmployee: Error - Tipo: ${e.runtimeType}, Mensaje: $e');
      rethrow; // Solo propagar, no modificar
    }
  }

  // 🆕 NUEVO: Restaurar empleado eliminado
  @override
  Future<bool> restoreEmployee(String id) async {
    try {
      print('🏛️ Repository: Restaurando empleado: $id');
      return await remoteDataSource.restoreEmployee(id);
    } catch (e) {
      print('❌ Repository.restoreEmployee: $e');

      if (e is Failure) {
        rethrow;
      }

      throw ServerFailure(
          message: 'Error al restaurar el empleado: ${e.toString()}');
    }
  }

  // 🆕 NUEVO: Obtener solo empleados activos
  @override
  Future<List<EmployeeEntity>> getActiveEmployees() async {
    try {
      print('🏛️ Repository: Obteniendo solo empleados activos');
      return await remoteDataSource.getActiveEmployees();
    } catch (e) {
      print('❌ Repository.getActiveEmployees: $e');

      if (e is Failure) {
        rethrow;
      }

      throw ServerFailure(
          message: 'Error al cargar empleados activos: ${e.toString()}');
    }
  }

  // 🆕 NUEVO: Obtener solo empleados eliminados
  @override
  Future<List<EmployeeEntity>> getDeletedEmployees() async {
    try {
      print('🏛️ Repository: Obteniendo empleados eliminados');
      return await remoteDataSource.getDeletedEmployees();
    } catch (e) {
      print('❌ Repository.getDeletedEmployees: $e');

      if (e is Failure) {
        rethrow;
      }

      throw ServerFailure(
          message: 'Error al cargar empleados eliminados: ${e.toString()}');
    }
  }

  // 🆕 NUEVO: Obtener todos los empleados con opción de incluir eliminados
  @override
  Future<List<EmployeeEntity>> getAllEmployees(
      {bool includeDeleted = false}) async {
    try {
      print(
          '🏛️ Repository: Obteniendo todos los empleados, incluir eliminados: $includeDeleted');
      return await remoteDataSource.getEmployees(
          includeDeleted: includeDeleted);
    } catch (e) {
      print('❌ Repository.getAllEmployees: $e');

      if (e is Failure) {
        rethrow;
      }

      throw ServerFailure(
          message: 'Error al cargar todos los empleados: ${e.toString()}');
    }
  }
}
