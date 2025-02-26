import 'package:get/get.dart';
import 'package:login_signup/features/employees/data/datasources/employees_remote_datasource.dart';
import 'package:login_signup/features/employees/data/repositories/employees_repository_impl.dart';
import 'package:login_signup/features/employees/domain/usecases/create_employee_usecase.dart';
import 'package:login_signup/features/employees/domain/usecases/get_employee_by_id_usecase.dart';
import 'package:login_signup/features/employees/domain/usecases/get_employees_usecase.dart';
import 'package:login_signup/features/employees/presentation/controllers/employees_controller.dart';

class EmployeesModule {
  static Future<void> init() async {
    try {
      // Verificar primero si ya están registradas las dependencias
      if (Get.isRegistered<EmployeesController>()) {
        print('EmployeesModule ya inicializado');
        return;
      }

      // DataSource
      final remoteDataSource = EmployeesRemoteDataSource(
        dio: Get.find(),
        localStorage: Get.find(),
      );

      // Repository
      final repository = EmployeesRepositoryImpl(remoteDataSource);

      // UseCases
      final getEmployeesUseCase = GetEmployeesUseCase(repository);
      final getEmployeeByIdUseCase = GetEmployeeByIdUseCase(repository);
      final createEmployeeUseCase = CreateEmployeeUseCase(repository);

      // Registrar los casos de uso
      Get.put(getEmployeesUseCase, permanent: false);
      Get.put(getEmployeeByIdUseCase, permanent: false);
      Get.put(createEmployeeUseCase, permanent: false);

      // Controller con parámetros nombrados
      Get.put(
          EmployeesController(
            getEmployeesUseCase: getEmployeesUseCase,
            getEmployeeByIdUseCase: getEmployeeByIdUseCase,
            createEmployeeUseCase: createEmployeeUseCase,
          ),
          permanent: false);

      print('EmployeesModule inicializado exitosamente');
    } catch (e) {
      print('Error al inicializar EmployeesModule: $e');
    }
  }

  static void reset() {
    try {
      // Eliminar en orden inverso
      if (Get.isRegistered<EmployeesController>()) {
        Get.delete<EmployeesController>();
      }

      if (Get.isRegistered<GetEmployeesUseCase>()) {
        Get.delete<GetEmployeesUseCase>();
      }

      if (Get.isRegistered<GetEmployeeByIdUseCase>()) {
        Get.delete<GetEmployeeByIdUseCase>();
      }

      if (Get.isRegistered<CreateEmployeeUseCase>()) {
        Get.delete<CreateEmployeeUseCase>();
      }

      print('EmployeesModule reseteado correctamente');
    } catch (e) {
      print('Error al resetear EmployeesModule: $e');
    }
  }
}
