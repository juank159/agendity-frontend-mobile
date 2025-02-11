import 'package:dio/dio.dart';
import 'package:login_signup/features/employees/data/models/employee_model.dart';
import 'package:login_signup/shared/local_storage/local_storage.dart';

class EmployeesRemoteDataSource {
  final Dio dio;
  final LocalStorage localStorage;
  static const String endpoint = '/auth/employees';

  EmployeesRemoteDataSource({
    required this.dio,
    required this.localStorage,
  });

  Future<List<EmployeeModel>> getEmployees() async {
    try {
      final token = await localStorage.getToken();
      final response = await dio.get(
        endpoint,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        return (response.data as List)
            .map((json) => EmployeeModel.fromJson(json))
            .toList();
      }
      throw Exception('Failed to load employees');
    } catch (e) {
      throw Exception('Error loading employees: $e');
    }
  }

  Future<EmployeeModel> getEmployeeById(String id) async {
    try {
      final token = await localStorage.getToken();
      final response = await dio.get(
        '$endpoint/$id',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        return EmployeeModel.fromJson(response.data);
      }
      throw Exception('Employee not found');
    } catch (e) {
      throw Exception('Error getting employee: $e');
    }
  }
}
