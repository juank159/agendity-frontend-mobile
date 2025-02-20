import 'package:get/get.dart';
import 'package:login_signup/features/employees/domain/entities/employee_entity.dart';
import 'package:login_signup/features/employees/domain/usecases/get_employee_by_id_usecase.dart';
import 'package:login_signup/features/employees/domain/usecases/get_employees_usecase.dart';

class EmployeesController extends GetxController {
  final GetEmployeesUseCase getEmployeesUseCase;
  final GetEmployeeByIdUseCase getEmployeeByIdUseCase;

  final RxList<EmployeeEntity> employees = <EmployeeEntity>[].obs;
  final RxBool isLoading = false.obs;
  final Rx<String?> error = Rx<String?>(null);
  final Rx<EmployeeEntity?> selectedEmployee = Rx<EmployeeEntity?>(null);

  EmployeesController(
    this.getEmployeesUseCase,
    this.getEmployeeByIdUseCase,
  );

  Future<void> loadEmployees() async {
    try {
      isLoading.value = true;
      error.value = null;
      final result = await getEmployeesUseCase();
      print('Empleados cargados: ${result.length}');
      employees.assignAll(result);
    } catch (e) {
      print('Error cargando empleados: $e');
      error.value = e.toString();
      Get.snackbar(
        'Error',
        'No se pudieron cargar los empleados',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<EmployeeEntity?> getEmployeeById(String id) async {
    try {
      isLoading.value = true;
      error.value = null;
      final result = await getEmployeeByIdUseCase(id);
      return result;
    } catch (e) {
      error.value = e.toString();
      Get.snackbar(
        'Error',
        'No se pudo obtener el empleado',
        snackPosition: SnackPosition.BOTTOM,
      );
      return null;
    } finally {
      isLoading.value = false;
    }
  }

  void selectEmployee(EmployeeEntity employee) {
    selectedEmployee.value = employee;
  }

  void clearSelection() {
    selectedEmployee.value = null;
  }
}
