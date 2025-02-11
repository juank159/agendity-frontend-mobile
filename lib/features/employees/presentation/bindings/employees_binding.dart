import 'package:get/get.dart';
import 'package:login_signup/features/employees/data/datasources/employees_remote_datasource.dart';
import 'package:login_signup/features/employees/data/repositories/employees_repository_impl.dart';
import 'package:login_signup/features/employees/domain/repositories/employees_repository.dart';
import 'package:login_signup/features/employees/domain/usecases/get_employee_by_id_usecase.dart';
import 'package:login_signup/features/employees/domain/usecases/get_employees_usecase.dart';
import 'package:login_signup/features/employees/presentation/controllers/employees_controller.dart';

class EmployeesBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<EmployeesRemoteDataSource>(
      () => EmployeesRemoteDataSource(
        dio: Get.find(),
        localStorage: Get.find(),
      ),
    );

    Get.lazyPut<EmployeesRepository>(
      () => EmployeesRepositoryImpl(Get.find()),
    );

    Get.lazyPut<GetEmployeesUseCase>(
      () => GetEmployeesUseCase(Get.find()),
    );

    Get.lazyPut<GetEmployeeByIdUseCase>(
      () => GetEmployeeByIdUseCase(Get.find()),
    );

    Get.lazyPut<EmployeesController>(
      () => EmployeesController(
        Get.find(),
        Get.find(),
      ),
    );
  }
}
