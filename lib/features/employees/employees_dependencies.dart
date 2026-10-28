import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/network/api_client.dart';
import 'package:login_signup/features/employees/data/datasources/employees_remote_datasource.dart';
import 'package:login_signup/features/employees/data/repositories/employees_repository_impl.dart';
import 'package:login_signup/features/employees/domain/repositories/employees_repository.dart';
import 'package:login_signup/features/employees/domain/usecases/create_employee_usecase.dart';
import 'package:login_signup/features/employees/domain/usecases/delete_employee_usecase.dart';
import 'package:login_signup/features/employees/domain/usecases/get_deleted_employees_usecase.dart';
import 'package:login_signup/features/employees/domain/usecases/get_employee_by_id_usecase.dart';
import 'package:login_signup/features/employees/domain/usecases/get_employees_usecase.dart';
import 'package:login_signup/features/employees/domain/usecases/request_employee_verification_code_usecase.dart';
import 'package:login_signup/features/employees/domain/usecases/restore_employee_usecase.dart';
import 'package:login_signup/features/employees/domain/usecases/toggle_employee_status_usecase.dart';
import 'package:login_signup/features/employees/domain/usecases/update_employee_usecase.dart';
import 'package:login_signup/features/employees/domain/usecases/verify_employee_email_usecase.dart';

/// Datasource, repositorio y use cases de profesionales (ARQUITECTURA §4).
/// Los controllers los registran los bindings.
abstract final class EmployeesDependencies {
  static void init() {
    Get.lazyPut<EmployeesRemoteDataSource>(
      () => EmployeesRemoteDataSourceImpl(Get.find<Dio>(tag: apiClientTag)),
      fenix: true,
    );
    Get.lazyPut<EmployeesRepository>(
      () => EmployeesRepositoryImpl(Get.find<EmployeesRemoteDataSource>()),
      fenix: true,
    );

    Get.lazyPut(() => GetEmployeesUseCase(Get.find<EmployeesRepository>()),
        fenix: true);
    Get.lazyPut(
        () => GetDeletedEmployeesUseCase(Get.find<EmployeesRepository>()),
        fenix: true);
    Get.lazyPut(() => GetEmployeeByIdUseCase(Get.find<EmployeesRepository>()),
        fenix: true);
    Get.lazyPut(() => CreateEmployeeUseCase(Get.find<EmployeesRepository>()),
        fenix: true);
    Get.lazyPut(() => UpdateEmployeeUseCase(Get.find<EmployeesRepository>()),
        fenix: true);
    Get.lazyPut(
        () => ToggleEmployeeStatusUseCase(Get.find<EmployeesRepository>()),
        fenix: true);
    Get.lazyPut(() => DeleteEmployeeUseCase(Get.find<EmployeesRepository>()),
        fenix: true);
    Get.lazyPut(() => RestoreEmployeeUseCase(Get.find<EmployeesRepository>()),
        fenix: true);
    Get.lazyPut(
        () => RequestEmployeeVerificationCodeUseCase(
            Get.find<EmployeesRepository>()),
        fenix: true);
    Get.lazyPut(
        () => VerifyEmployeeEmailUseCase(Get.find<EmployeesRepository>()),
        fenix: true);
  }
}
