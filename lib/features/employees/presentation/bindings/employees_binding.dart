import 'package:get/get.dart';
import 'package:login_signup/features/employees/presentation/controllers/employees_controller.dart';
import 'package:login_signup/features/services/presentation/bindings/services_binding.dart';

/// Rutas de la gestión de profesionales. Los use cases los registra
/// `EmployeesDependencies` al arrancar; aquí solo van los controllers.
class EmployeesBinding implements Bindings {
  @override
  void dependencies() {
    ServicesBinding.registerController();
    registerController();
  }

  /// Registra el `EmployeesController` si falta. Lo llaman el arranque,
  /// `SessionScope.reset()` (logout) y las rutas de la feature. Sigue
  /// `permanent` hasta que FP lo ligue a sus rutas (4.07): la feature navega
  /// con `offAllNamed` y un controller ligado a la ruta se perdería.
  static void registerController() {
    if (Get.isRegistered<EmployeesController>()) return;
    Get.put<EmployeesController>(
      EmployeesController(
        getEmployeesUseCase: Get.find(),
        getEmployeeByIdUseCase: Get.find(),
        createEmployeeUseCase: Get.find(),
        updateEmployeeUseCase: Get.find(),
        deleteEmployeeUseCase: Get.find(),
        toggleEmployeeStatusUseCase: Get.find(),
        restoreEmployeeUseCase: Get.find(),
        getDeletedEmployeesUseCase: Get.find(),
      ),
      permanent: true,
    );
  }
}
