import 'package:login_signup/features/employees/data/datasources/employees_remote_datasource.dart';
import 'package:login_signup/features/employees/data/exceptions/employee_exception.dart';
import 'package:login_signup/features/employees/domain/entities/employee_entity.dart';
import 'package:login_signup/features/employees/domain/repositories/employees_repository.dart';

class EmployeesRepositoryImpl implements EmployeesRepository {
  final EmployeesRemoteDataSource remoteDataSource;

  EmployeesRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<EmployeeEntity>> getEmployees() async {
    try {
      return await remoteDataSource.getEmployees();
    } catch (e) {
      throw EmployeeException(message: e.toString());
    }
  }

  @override
  Future<EmployeeEntity> getEmployeeById(String id) async {
    try {
      return await remoteDataSource.getEmployeeById(id);
    } catch (e) {
      throw EmployeeException(message: e.toString());
    }
  }
}
