// import 'package:dio/dio.dart';
// import 'package:login_signup/features/employees/data/models/employee_model.dart';
// import 'package:login_signup/shared/local_storage/local_storage.dart';

// class EmployeesRemoteDataSource {
//   final Dio dio;
//   final LocalStorage localStorage;
//   static const String endpoint = '/auth/employees';

//   EmployeesRemoteDataSource({
//     required this.dio,
//     required this.localStorage,
//   });

//   Future<List<EmployeeModel>> getEmployees() async {
//     try {
//       final token = await localStorage.getToken();
//       final response = await dio.get(
//         endpoint,
//         options: Options(headers: {'Authorization': 'Bearer $token'}),
//       );

//       if (response.statusCode == 200) {
//         return (response.data as List)
//             .map((json) => EmployeeModel.fromJson(json))
//             .toList();
//       }
//       throw Exception('Failed to load employees');
//     } catch (e) {
//       throw Exception('Error loading employees: $e');
//     }
//   }

//   Future<EmployeeModel> getEmployeeById(String id) async {
//     try {
//       final token = await localStorage.getToken();
//       final response = await dio.get(
//         '$endpoint/$id',
//         options: Options(headers: {'Authorization': 'Bearer $token'}),
//       );

//       if (response.statusCode == 200) {
//         return EmployeeModel.fromJson(response.data);
//       }
//       throw Exception('Employee not found');
//     } catch (e) {
//       throw Exception('Error getting employee: $e');
//     }
//   }
// }

import 'package:dio/dio.dart';
import 'package:login_signup/features/employees/data/models/employee_model.dart';
import 'package:login_signup/shared/local_storage/local_storage.dart';

class EmployeesRemoteDataSource {
  final Dio dio;
  final LocalStorage localStorage;

  // Endpoints separados para plural y singular
  static const String endpointPlural = '/auth/employees';
  static const String endpointSingular = '/auth/employee';

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
}
