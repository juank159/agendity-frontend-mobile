// lib/features/employees/data/datasources/employees_remote_datasource.dart

import 'package:dio/dio.dart';
import 'package:login_signup/features/employees/data/models/employee_model.dart';
import 'package:login_signup/features/employees/domain/entities/employee_entity.dart';
import 'package:login_signup/shared/local_storage/local_storage.dart';

class EmployeesRemoteDataSource {
  final Dio dio;
  final LocalStorage localStorage;

  // Endpoints separados para plural y singular
  static const String endpointPlural = '/auth/employees';
  static const String endpointSingular = '/auth/employee';
  static const String endpointRegister = '/auth/register/employee';

  EmployeesRemoteDataSource({
    required this.dio,
    required this.localStorage,
  });

  Future<List<EmployeeModel>> getEmployees() async {
    try {
      final token = await localStorage.getToken();
      print('Obteniendo lista de empleados desde: $endpointPlural');

      final response = await dio.get(
        endpointPlural,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        final employeesList = (response.data as List)
            .map((json) => EmployeeModel.fromJson(json))
            .toList();
        print('Empleados obtenidos: ${employeesList.length}');
        return employeesList;
      }
      throw Exception('Failed to load employees');
    } catch (e) {
      print('Error al cargar empleados: $e');
      throw Exception('Error loading employees: $e');
    }
  }

  Future<EmployeeModel> getEmployeeById(String id) async {
    try {
      final token = await localStorage.getToken();
      final url = '$endpointSingular/$id';
      print('Obteniendo empleado desde: $url');

      final response = await dio.get(
        url,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        print('Empleado obtenido con éxito: ${response.data}');
        return EmployeeModel.fromJson(response.data);
      }
      throw Exception('Employee not found');
    } catch (e) {
      print('Error al obtener empleado con ID $id: $e');
      throw Exception('Error getting employee: $e');
    }
  }

  Future<EmployeeModel> createEmployee(
      EmployeeEntity employee, String password) async {
    try {
      final token = await localStorage.getToken();

      // Convertir el empleado a un mapa y añadir la contraseña
      final Map<String, dynamic> data =
          (employee as EmployeeModel).toCreateJson(password: password);

      print('Enviando datos al servidor: $data');

      final response = await dio.post(
        endpointRegister,
        data: data,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      return EmployeeModel.fromJson(response.data);
    } catch (e) {
      print('Error creando empleado en DataSource: $e');
      throw Exception('Failed to create employee');
    }
  }
}
