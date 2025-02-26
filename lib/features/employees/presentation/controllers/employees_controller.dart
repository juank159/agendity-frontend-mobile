import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/features/employees/data/models/employee_model.dart';
import 'package:login_signup/features/employees/domain/entities/employee_entity.dart';
import 'package:login_signup/features/employees/domain/usecases/create_employee_usecase.dart';
import 'package:login_signup/features/employees/domain/usecases/get_employee_by_id_usecase.dart';
import 'package:login_signup/features/employees/domain/usecases/get_employees_usecase.dart';

class EmployeesController extends GetxController {
  final GetEmployeesUseCase getEmployeesUseCase;
  final GetEmployeeByIdUseCase getEmployeeByIdUseCase;
  final CreateEmployeeUseCase createEmployeeUseCase;

  final RxList<EmployeeEntity> employees = <EmployeeEntity>[].obs;
  final RxBool isLoading = false.obs;
  final Rx<String?> error = Rx<String?>(null);
  final Rx<EmployeeEntity?> selectedEmployee = Rx<EmployeeEntity?>(null);

  // Para la creación de empleados
  final RxString name = ''.obs;
  final RxString lastname = ''.obs;
  final RxString email = ''.obs;
  final RxString phone = ''.obs;
  final RxString password = ''.obs;
  final RxList<String> selectedServiceIds = <String>[].obs;
  final RxMap<String, Map<String, String>> schedule =
      <String, Map<String, String>>{}.obs;

  // Días de la semana
  final List<String> weekdays = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday'
  ];

  EmployeesController({
    GetEmployeesUseCase? getEmployeesUseCase,
    GetEmployeeByIdUseCase? getEmployeeByIdUseCase,
    CreateEmployeeUseCase? createEmployeeUseCase,
  })  : this.getEmployeesUseCase =
            getEmployeesUseCase ?? Get.find<GetEmployeesUseCase>(),
        this.getEmployeeByIdUseCase =
            getEmployeeByIdUseCase ?? Get.find<GetEmployeeByIdUseCase>(),
        this.createEmployeeUseCase =
            createEmployeeUseCase ?? Get.find<CreateEmployeeUseCase>();

  @override
  void onInit() {
    super.onInit();
    // Inicializar el horario por defecto
    initSchedule();
  }

  @override
  void onClose() {
    super.onClose();
  }

  Future<void> refreshOnFocus() async {
    // Puedes decidir si quieres cargar todo o usar una API más eficiente
    // que solo devuelva cambios
    await loadEmployees();
  }

  void initSchedule() {
    for (var day in weekdays) {
      schedule[day] = {'start': '09:00', 'end': '18:00'};
    }
  }

  Future<void> initializeEmployees() async {
    if (employees.isEmpty) {
      await loadEmployees();
    }
  }

  Future<void> loadEmployees() async {
    try {
      isLoading.value = true;
      error.value = null;
      // Verificar que getEmployeesUseCase no sea nulo
      if (getEmployeesUseCase == null) {
        throw Exception(
            'No se pudo cargar los empleados: getEmployeesUseCase no disponible');
      }
      final result = await getEmployeesUseCase!();
      print('Empleados cargados: ${result.length}');
      employees.assignAll(result);
      update();
    } finally {
      isLoading.value = false;
      update(); // Segunda actualización para asegurar que se refleje el cambio de isLoading
    }
  }

  Future<EmployeeEntity?> getEmployeeById(String id) async {
    try {
      // Comprobar si ya está en la lista local
      final localEmployee = employees.firstWhereOrNull((e) => e.id == id);
      if (localEmployee != null) {
        return localEmployee;
      }

      // Si no, cargar desde el servidor
      isLoading.value = true;
      error.value = null;
      final result = await getEmployeeByIdUseCase(id);
      return result;
    } catch (e) {
      error.value = e.toString();
      print('Error al obtener empleado: $e');
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

  // Métodos para crear empleado
  void updateName(String value) => name.value = value;
  void updateLastname(String value) => lastname.value = value;
  void updateEmail(String value) => email.value = value;
  void updatePhone(String value) => phone.value = value;
  void updatePassword(String value) => password.value = value;

  void toggleServiceSelection(String serviceId) {
    if (selectedServiceIds.contains(serviceId)) {
      selectedServiceIds.remove(serviceId);
    } else {
      selectedServiceIds.add(serviceId);
    }

    // Imprimir servicios seleccionados para depuración
    print('Servicios seleccionados: ${selectedServiceIds.join(", ")}');

    // Notificar a los widgets para actualizarse
    update();
  }

  void updateSchedule(String day, String type, String value) {
    if (!schedule.containsKey(day)) {
      schedule[day] = {'start': '09:00', 'end': '18:00'};
    }
    schedule[day]![type] = value;

    // Notificar a los GetBuilder para actualizar la UI
    update();
  }

  bool validateEmployeeData() {
    if (name.value.isEmpty ||
        lastname.value.isEmpty ||
        email.value.isEmpty ||
        password.value.isEmpty ||
        phone.value.isEmpty) {
      Get.snackbar(
        'Error',
        'Todos los campos marcados con * son obligatorios',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
      );
      return false;
    }

    if (selectedServiceIds.isEmpty) {
      Get.snackbar(
        'Error',
        'Debe seleccionar al menos un servicio',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
      );
      return false;
    }

    if (!GetUtils.isEmail(email.value)) {
      Get.snackbar(
        'Error',
        'El email no es válido',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
      );
      return false;
    }

    if (password.value.length < 8) {
      Get.snackbar(
        'Error',
        'La contraseña debe tener al menos 8 caracteres',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
      );
      return false;
    }

    return true;
  }

  Future<bool> createEmployee() async {
    if (!validateEmployeeData()) {
      return false;
    }

    try {
      isLoading.value = true;
      error.value = null;

      // Filtrar días sin horario o con horarios incompletos
      final filteredSchedule = <String, Map<String, String>>{};
      schedule.forEach((day, hours) {
        if (hours['start'] != null &&
            hours['end'] != null &&
            hours['start']!.isNotEmpty &&
            hours['end']!.isNotEmpty) {
          filteredSchedule[day] = hours;
        }
      });

      // Verificar que password no esté vacío
      if (password.value.isEmpty) {
        Get.snackbar(
          'Error',
          'La contraseña es obligatoria',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red[100],
          colorText: Colors.red[900],
        );
        return false;
      }

      // Crear el modelo de empleado
      final employee = EmployeeModel(
        id: '', // El ID lo asigna el backend
        name: name.value,
        lastname: lastname.value,
        email: email.value,
        phone: phone.value,
        isActive: true,
        roles: [], // Roles vacíos, el backend los asignará
        serviceIds: selectedServiceIds,
        schedule: filteredSchedule,
      );

      // Usar el método toCreateJson con la contraseña
      final employeeData = employee.toCreateJson(password: password.value);

      // Mostrar los datos que se van a enviar (para depuración)
      print('Creando empleado en: /auth/register/employee');
      print('Datos: $employeeData');

      // Pasa el modelo al useCase
      final result = await createEmployeeUseCase(employee, password.value);

// Añadir el nuevo empleado a la lista
      employees.add(result);

// Limpiar el formulario
      clearForm();

// Mostrar mensaje de éxito
      Get.snackbar(
        'Éxito',
        'Profesional creado correctamente',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green[100],
        colorText: Colors.green[900],
      );

// Navegar a la pantalla de lista de empleados
      Get.offAllNamed('/employees');

      return true;
    } catch (e) {
      error.value = e.toString();
      print('Error al crear empleado: $e');
      Get.snackbar(
        'Error',
        'No se pudo crear el profesional: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  void clearForm() {
    name.value = '';
    lastname.value = '';
    email.value = '';
    phone.value = '';
    password.value = '';
    selectedServiceIds.clear();
    initSchedule();
  }

  List<EmployeeEntity> getActiveEmployees() {
    return employees.where((employee) => employee.isActive).toList();
  }
}
