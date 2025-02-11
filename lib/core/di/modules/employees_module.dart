import 'package:get/get.dart';
import 'package:login_signup/features/employees/data/datasources/employees_remote_datasource.dart';
import 'package:login_signup/features/employees/data/repositories/employees_repository_impl.dart';
import 'package:login_signup/features/employees/domain/usecases/get_employee_by_id_usecase.dart';
import 'package:login_signup/features/employees/domain/usecases/get_employees_usecase.dart';
import 'package:login_signup/features/employees/presentation/controllers/employees_controller.dart';

class EmployeesModule {
  static Future<void> init() async {
    final remoteDataSource = EmployeesRemoteDataSource(
      dio: Get.find(),
      localStorage: Get.find(),
    );

    final repository = EmployeesRepositoryImpl(remoteDataSource);

    Get.put(GetEmployeesUseCase(repository));
    Get.put(GetEmployeeByIdUseCase(repository));
    Get.put(EmployeesController(
      Get.find(),
      Get.find(),
    ));
  }
}
