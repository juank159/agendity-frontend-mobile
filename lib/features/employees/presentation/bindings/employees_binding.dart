import 'package:get/get.dart';
import 'package:login_signup/features/employees/presentation/controllers/edit_employee_controller.dart';
import 'package:login_signup/features/employees/presentation/controllers/employees_controller.dart';
import 'package:login_signup/features/employees/presentation/controllers/new_employee_controller.dart';

/// Lista de profesionales (`/employees`). **Único** registro de
/// `EmployeesController`: vive con su ruta (sin `permanent`); ninguna otra
/// feature lo crea ni lo busca. Datasource, repositorio y use cases los
/// registra `EmployeesDependencies`.
class EmployeesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => EmployeesController(
          getEmployeesUseCase: Get.find(),
          getDeletedEmployeesUseCase: Get.find(),
          toggleEmployeeStatusUseCase: Get.find(),
          deleteEmployeeUseCase: Get.find(),
          restoreEmployeeUseCase: Get.find(),
        ));
  }
}

/// Alta de profesional (`/employees/new`).
class NewEmployeeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => NewEmployeeController(
          createEmployeeUseCase: Get.find(),
          getServicesUseCase: Get.find(),
        ));
  }
}

/// Edición de profesional (`/employees/edit`, id en
/// `arguments['employeeId']`).
class EditEmployeeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => EditEmployeeController(
          getEmployeeByIdUseCase: Get.find(),
          updateEmployeeUseCase: Get.find(),
          getServicesUseCase: Get.find(),
        ));
  }
}
