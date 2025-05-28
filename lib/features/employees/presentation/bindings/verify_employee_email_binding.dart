import 'package:get/get.dart';
import 'package:login_signup/features/employees/domain/repositories/employees_repository.dart';
import 'package:login_signup/features/employees/domain/usecases/verify_employee_email_usecase.dart';
import 'package:login_signup/features/employees/domain/usecases/toggle_employee_status_usecase.dart';
import 'package:login_signup/features/employees/presentation/controllers/verify_employee_email_controller.dart';

class VerifyEmployeeEmailBinding extends Bindings {
  @override
  void dependencies() {
    print('Iniciando VerifyEmployeeEmailBinding...');

    try {
      // Comprobar si las dependencias ya están registradas
      if (Get.isRegistered<EmployeesRepository>()) {
        final repository = Get.find<EmployeesRepository>();

        // Registrar los casos de uso
        if (!Get.isRegistered<VerifyEmployeeEmailUseCase>()) {
          Get.lazyPut<VerifyEmployeeEmailUseCase>(
            () => VerifyEmployeeEmailUseCase(repository),
            fenix: true, // Permitir recrearlo si es necesario
          );
        }

        if (!Get.isRegistered<ToggleEmployeeStatusUseCase>()) {
          Get.lazyPut<ToggleEmployeeStatusUseCase>(
            () => ToggleEmployeeStatusUseCase(repository),
            fenix: true, // Permitir recrearlo si es necesario
          );
        }

        // Registrar el controlador - usamos put en lugar de lazyPut para que se inicialice inmediatamente
        Get.put<VerifyEmployeeEmailController>(
          VerifyEmployeeEmailController(
            verifyEmployeeEmailUseCase: Get.find<VerifyEmployeeEmailUseCase>(),
            toggleEmployeeStatusUseCase:
                Get.find<ToggleEmployeeStatusUseCase>(),
          ),
          permanent: false, // No permanente para que se pueda liberar
        );

        print('VerifyEmployeeEmailController registrado correctamente');
      } else {
        print('ERROR: EmployeesRepository no encontrado');
        throw Exception(
            'EmployeesRepository debe estar registrado antes de usar VerifyEmployeeEmailBinding');
      }
    } catch (e) {
      print('Error al registrar dependencias: $e');
      throw e; // Re-lanzar para que sea visible
    }
  }
}
