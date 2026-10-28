import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/routes/routes.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/features/employees/domain/entities/employee_entity.dart';
import 'package:login_signup/features/employees/domain/entities/employee_input.dart';
import 'package:login_signup/features/employees/domain/entities/service_assignment.dart';
import 'package:login_signup/features/employees/domain/entities/work_hours.dart';
import 'package:login_signup/features/employees/domain/failures/employee_failures.dart';
// CASOS DE USO
import 'package:login_signup/features/employees/domain/usecases/create_employee_usecase.dart';
import 'package:login_signup/features/employees/domain/usecases/delete_employee_usecase.dart';
import 'package:login_signup/features/employees/domain/usecases/get_deleted_employees_usecase.dart';
import 'package:login_signup/features/employees/domain/usecases/get_employee_by_id_usecase.dart';
import 'package:login_signup/features/employees/domain/usecases/get_employees_usecase.dart';
import 'package:login_signup/features/employees/domain/usecases/restore_employee_usecase.dart';
import 'package:login_signup/features/employees/domain/usecases/toggle_employee_status_usecase.dart';
import 'package:login_signup/features/employees/domain/usecases/update_employee_usecase.dart';

import 'package:login_signup/features/employees/presentation/bindings/verify_employee_email_binding.dart';
import 'package:login_signup/features/employees/presentation/screens/verify_employee_email_screen.dart';
import 'package:login_signup/core/errors/failures.dart';

class EmployeesController extends GetxController {
  final GetEmployeesUseCase getEmployeesUseCase;
  final GetEmployeeByIdUseCase getEmployeeByIdUseCase;
  final CreateEmployeeUseCase createEmployeeUseCase;
  final UpdateEmployeeUseCase updateEmployeeUseCase;
  final DeleteEmployeeUseCase deleteEmployeeUseCase;
  final ToggleEmployeeStatusUseCase toggleEmployeeStatusUseCase;
  // 🆕 NUEVOS CASOS DE USO
  final RestoreEmployeeUseCase restoreEmployeeUseCase;
  final GetDeletedEmployeesUseCase getDeletedEmployeesUseCase;

  // Variables observables para la lista de empleados
  final RxList<EmployeeEntity> employees = <EmployeeEntity>[].obs;
  final RxBool isLoading = false.obs;
  final Rx<String?> error = Rx<String?>(null);
  final Rx<EmployeeEntity?> selectedEmployee = Rx<EmployeeEntity?>(null);

  // 🆕 NUEVAS: Variables para manejar empleados eliminados
  final RxList<EmployeeEntity> deletedEmployees = <EmployeeEntity>[].obs;
  final RxBool isLoadingDeleted = false.obs;
  final RxBool showDeletedEmployees = false.obs;

  // Para la creación/edición de empleados
  final RxString name = ''.obs;
  final RxString lastname = ''.obs;
  final RxString email = ''.obs;
  final RxString phone = ''.obs;
  final RxString password = ''.obs;

  // Controladores para manejar el cursor en los campos de texto
  final TextEditingController nameController = TextEditingController();
  final TextEditingController lastnameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  // Variables para servicios y horarios
  final RxList<String> selectedServiceIds = <String>[].obs;
  final RxMap<String, Map<String, String>> schedule =
      <String, Map<String, String>>{}.obs;
  final RxMap<String, double> serviceCommissions = <String, double>{}.obs;

  // Para la búsqueda
  final RxString searchQuery = ''.obs;
  final RxList<EmployeeEntity> filteredEmployees = <EmployeeEntity>[].obs;
  // 🆕 NUEVA: Para filtrar empleados eliminados
  final RxList<EmployeeEntity> filteredDeletedEmployees =
      <EmployeeEntity>[].obs;

  // Para la edición
  final RxBool isEditMode = false.obs;
  final RxString editingEmployeeId = ''.obs;

  // Lista de días habilitados
  final RxList<String> enabledDays = <String>[].obs;

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

  // 🔄 CONSTRUCTOR ACTUALIZADO con nuevos casos de uso
  EmployeesController({
    required this.getEmployeesUseCase,
    required this.getEmployeeByIdUseCase,
    required this.createEmployeeUseCase,
    required this.updateEmployeeUseCase,
    required this.deleteEmployeeUseCase,
    required this.toggleEmployeeStatusUseCase,
    required this.restoreEmployeeUseCase,
    required this.getDeletedEmployeesUseCase,
  });

  @override
  void onInit() {
    super.onInit();
    _initTextControllers();
    initSchedule();

    // Reaccionar a cambios en la búsqueda
    ever(searchQuery, (_) => filterEmployees());

    // Inicialmente, filteredEmployees es igual a employees
    ever(employees, (_) => filterEmployees());

    // 🆕 NUEVO: Reaccionar a cambios en empleados eliminados
    ever(deletedEmployees, (_) => filterDeletedEmployees());
  }

  void filterDeletedEmployees() {
    if (searchQuery.isEmpty) {
      filteredDeletedEmployees.assignAll(deletedEmployees);
    } else {
      final query = searchQuery.value.toLowerCase();
      filteredDeletedEmployees.assignAll(deletedEmployees.where((employee) =>
          employee.name.toLowerCase().contains(query) ||
          employee.lastname.toLowerCase().contains(query) ||
          employee.email.toLowerCase().contains(query) ||
          employee.phone.toLowerCase().contains(query)));
    }
    update();
  }

  void toggleDeletedEmployeesView() {
    showDeletedEmployees.value = !showDeletedEmployees.value;

    if (showDeletedEmployees.value && deletedEmployees.isEmpty) {
      loadDeletedEmployees();
    }

    update();
  }

  // Inicializar controladores de texto (sin listeners para evitar el problema de inversión)
  void _initTextControllers() {
    // Sin listeners para evitar el problema de texto invertido
    // Los valores serán actualizados por onChanged en los TextField
  }

  @override
  void onClose() {
    // Liberar los controladores cuando se cierra el controlador
    // clearForm escribe en los TextEditingController: antes de liberarlos.
    clearForm();
    nameController.dispose();
    lastnameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  Future<void> refreshOnFocus() async {
    await loadEmployees();
    // También refrescar eliminados si se están mostrando
    if (showDeletedEmployees.value) {
      await loadDeletedEmployees();
    }
  }

  // Método para inicializar o reiniciar los días habilitados
  void initEnabledDays({List<String>? initialDays}) {
    enabledDays.clear();

    // Por defecto, habilitar lunes a viernes si no se especifican días iniciales
    if (initialDays != null && initialDays.isNotEmpty) {
      enabledDays.assignAll(initialDays);
    } else {
      // Por defecto, solo se habilitan los días laborables (lunes a viernes)
      enabledDays
          .assignAll(['monday', 'tuesday', 'wednesday', 'thursday', 'friday']);
    }

    // Asegurarse de que solo hay horarios para los días habilitados
    _syncScheduleWithEnabledDays();
    update();
  }

  // Método para inicializar el horario
  void initSchedule() {
    // Limpiar el horario existente
    schedule.clear();

    // Inicializar los días habilitados si aún no se ha hecho
    if (enabledDays.isEmpty) {
      initEnabledDays();
    }

    // Solo inicializar horarios para los días habilitados
    for (var day in enabledDays) {
      schedule[day] = {'start': '09:00', 'end': '18:00'};
    }

    update();
  }

  // Método para alternar el estado habilitado de un día
  void toggleDayEnabled(String day, bool enabled) {
    print('Ejecutando toggleDayEnabled para $day: $enabled');
    print('Días habilitados antes: $enabledDays');
    print('Horario antes: $schedule');

    if (enabled && !enabledDays.contains(day)) {
      // Añadir el día a la lista de habilitados
      enabledDays.add(day);
      print('Día $day habilitado');

      // Asegurarse de que el día tenga un horario establecido
      if (!schedule.containsKey(day)) {
        schedule[day] = {'start': '09:00', 'end': '18:00'};
        print('Horario por defecto establecido para $day');
      }
    } else if (!enabled && enabledDays.contains(day)) {
      // Quitar el día de la lista de habilitados
      enabledDays.remove(day);
      print('Día $day deshabilitado');
    }

    // Forzar sincronización explícita
    _syncScheduleWithEnabledDays();

    print('Días habilitados después: $enabledDays');
    print('Horario después: $schedule');

    // Asegurarse de que la UI se actualice
    update();
  }

  // Método privado para sincronizar el horario con los días habilitados
  void _syncScheduleWithEnabledDays() {
    print('Sincronizando horario con días habilitados');
    print('Días habilitados: $enabledDays');
    print('Horario antes de sincronizar: $schedule');

    // Crear una copia del horario actual para preservar los valores
    final Map<String, Map<String, String>> currentSchedule = {};
    schedule.forEach((day, times) {
      currentSchedule[day] = {...times}; // Copia profunda
    });

    // Crear el horario filtrado
    final Map<String, Map<String, String>> filteredSchedule = {};

    // Solo incluir los días habilitados, pero preservar sus horarios
    for (final day in enabledDays) {
      // Usar el horario existente si está disponible, o uno por defecto
      filteredSchedule[day] =
          currentSchedule[day] ?? {'start': '09:00', 'end': '18:00'};
    }

    // Reemplazar el horario completo con el filtrado
    schedule.clear();
    schedule.addAll(filteredSchedule);

    print('Horario después de sincronizar: $schedule');
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

      final result = await getEmployeesUseCase(NoParams());
      result.fold((failure) {
        error.value = failure.message;
        Get.snackbar(
          'Error',
          'No se pudieron cargar los profesionales: ${failure.message}',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red[100],
          colorText: Colors.red[900],
        );
      }, employees.assignAll);
    } finally {
      isLoading.value = false;
      update();
    }
  }

  Future<void> loadDeletedEmployees() async {
    try {
      isLoadingDeleted.value = true;
      error.value = null;

      final result = await getDeletedEmployeesUseCase(NoParams());
      result.fold((failure) {
        error.value = failure.message;
        Get.snackbar(
          'Error',
          'No se pudieron cargar los empleados eliminados: ${failure.message}',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red[100],
          colorText: Colors.red[900],
        );
      }, deletedEmployees.assignAll);
    } finally {
      isLoadingDeleted.value = false;
      update();
    }
  }

  // Método para filtrar empleados
  void filterEmployees() {
    if (searchQuery.isEmpty) {
      filteredEmployees.assignAll(employees);
    } else {
      final query = searchQuery.value.toLowerCase();
      filteredEmployees.assignAll(employees.where((employee) =>
          employee.name.toLowerCase().contains(query) ||
          employee.lastname.toLowerCase().contains(query) ||
          employee.email.toLowerCase().contains(query) ||
          employee.phone.toLowerCase().contains(query)));
    }

    // También filtrar eliminados si la búsqueda está activa
    filterDeletedEmployees();
    update();
  }

  Future<void> refreshAllData() async {
    try {
      isLoading.value = true;
      isLoadingDeleted.value = true;

      // Cargar en paralelo
      await Future.wait([
        loadEmployees(),
        if (showDeletedEmployees.value || deletedEmployees.isNotEmpty)
          loadDeletedEmployees(),
      ]);

      print('✅ Controller: Todos los datos refrescados');
    } catch (e) {
      print('❌ Controller: Error refrescando datos - $e');
    } finally {
      isLoading.value = false;
      isLoadingDeleted.value = false;
      update();
    }
  }

// 🆕 NUEVO: Método para estadísticas rápidas
  Map<String, int> getEmployeeStats() {
    return {
      'total': employees.length + deletedEmployees.length,
      'active': employees.length,
      'deleted': deletedEmployees.length,
      'activeFiltered': filteredEmployees.length,
      'deletedFiltered': filteredDeletedEmployees.length,
    };
  }

  // Método para actualizar la consulta de búsqueda
  void updateSearchQuery(String value) {
    searchQuery.value = value;
  }

  // Método para actualizar el porcentaje de comisión
  void updateServiceCommission(String serviceId, double percentage) {
    serviceCommissions[serviceId] = percentage;
    update();
  }

  Future<EmployeeEntity?> getEmployeeById(String id) async {
    // Comprobar si ya está en la lista local
    final localEmployee = employees.firstWhereOrNull((e) => e.id == id);
    if (localEmployee != null) {
      return localEmployee;
    }

    // Si no, cargar desde el servidor
    try {
      isLoading.value = true;
      error.value = null;
      final result = await getEmployeeByIdUseCase(id);
      return result.fold((failure) {
        error.value = failure.message;
        return null;
      }, (employee) => employee);
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

  // Métodos para cargar un empleado para edición
  void loadEmployeeForEditing(String employeeId) async {
    try {
      isLoading.value = true;
      error.value = null;
      isEditMode.value = true;
      editingEmployeeId.value = employeeId;

      // Obtener el empleado
      final employee = await getEmployeeById(employeeId);
      if (employee != null) {
        // Log para depuración
        print(
            'Cargando datos del empleado: ${employee.name} ${employee.lastname}');
        print('Horario del empleado: ${employee.schedule}');

        // Cargar los datos en los controladores de texto y valores Rx
        nameController.text = employee.name;
        lastnameController.text = employee.lastname;
        emailController.text = employee.email;
        phoneController.text = employee.phone;
        passwordController.text = ''; // Limpiar contraseña para edición

        // También actualizar los valores Rx para mantener sincronización
        name.value = employee.name;
        lastname.value = employee.lastname;
        email.value = employee.email;
        phone.value = employee.phone;
        password.value = '';

        // Cargar servicios seleccionados
        selectedServiceIds.clear();
        serviceCommissions.clear();

        selectedServiceIds.assignAll(employee.serviceIds);
        employee.serviceAssignments.forEach((serviceId, assignment) {
          serviceCommissions[serviceId] = assignment.commissionPercentage;
        });

        // Cargar horario
        if (employee.schedule.isNotEmpty) {
          print('Asignando horario: ${employee.schedule}');
          // El modelo ya normaliza las horas a HH:mm.
          schedule.assignAll({
            for (final entry in employee.schedule.entries)
              entry.key: {'start': entry.value.start, 'end': entry.value.end},
          });

          // IMPORTANTE: Inicializar días habilitados con las claves exactas del horario
          List<String> activeDays = employee.schedule.keys.toList();
          print('Días activos detectados: $activeDays');
          initEnabledDays(initialDays: activeDays);
        } else {
          print('No hay horario, inicializando por defecto');
          schedule.clear();
          initSchedule();
          initEnabledDays(); // Usar días predeterminados (lunes a viernes)
        }

        update();
      }
    } catch (e) {
      error.value = e.toString();
      print('Error al cargar empleado para edición: $e');
      Get.snackbar(
        'Error',
        'No se pudo cargar el profesional para editar: ${e.toString()}',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
      );
    } finally {
      isLoading.value = false;
      update();
    }
  }

  // Métodos simplificados para actualizar valores en los campos de texto
  void updateName(String value) {
    name.value = value;
  }

  void updateLastname(String value) {
    lastname.value = value;
  }

  void updateEmail(String value) {
    email.value = value;
  }

  void updatePhone(String value) {
    phone.value = value;
  }

  void updatePassword(String value) {
    password.value = value;
  }

  void toggleServiceSelection(String serviceId) {
    if (selectedServiceIds.contains(serviceId)) {
      selectedServiceIds.remove(serviceId);
    } else {
      selectedServiceIds.add(serviceId);
    }
    update();
  }

  void updateSchedule(String day, String type, String value) {
    if (!schedule.containsKey(day)) {
      schedule[day] = {'start': '09:00', 'end': '18:00'};
    }
    schedule[day]![type] = value;
    update();
  }

  // Método mejorado para validación completa
  bool validateEmployeeData({bool isEdit = false}) {
    // Validación de campos obligatorios
    if (name.value.trim().isEmpty) {
      _showFieldError(
          'El nombre es obligatorio', 'Ingrese el nombre del profesional');
      return false;
    }

    if (lastname.value.trim().isEmpty) {
      _showFieldError(
          'El apellido es obligatorio', 'Ingrese el apellido del profesional');
      return false;
    }

    if (email.value.trim().isEmpty) {
      _showFieldError('El email es obligatorio',
          'Ingrese el correo electrónico del profesional');
      return false;
    }

    if (!GetUtils.isEmail(email.value.trim())) {
      _showFieldError('Email inválido', 'Ingrese un correo electrónico válido');
      return false;
    }

    if (phone.value.trim().isEmpty) {
      _showFieldError('El teléfono es obligatorio',
          'Ingrese el número de teléfono del profesional');
      return false;
    }

    if (phone.value.trim().length < 7) {
      _showFieldError('Teléfono inválido',
          'El número de teléfono debe tener al menos 7 dígitos');
      return false;
    }

    if (!isEdit && password.value.isEmpty) {
      _showFieldError('La contraseña es obligatoria',
          'Ingrese una contraseña para el profesional');
      return false;
    }

    if (!isEdit && password.value.length < 8) {
      _showFieldError(
          'Contraseña corta', 'La contraseña debe tener al menos 8 caracteres');
      return false;
    }

    // Validación de servicios seleccionados
    if (selectedServiceIds.isEmpty) {
      _showFieldError('Servicios requeridos',
          'Seleccione al menos un servicio para el profesional');
      return false;
    }

    // Validación de días habilitados
    if (enabledDays.isEmpty) {
      _showFieldError('Horario requerido',
          'Active al menos un día de trabajo para el profesional');
      return false;
    }

    // Si todo está bien
    return true;
  }

  // Método auxiliar para mostrar errores de campo
  void _showFieldError(String title, String message) {
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red[700]),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Entendido'),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  /// Crea el empleado (nace inactivo, 2.16) y abre la verificación de su
  /// email; al verificar, el backend lo activa.
  Future<bool> createEmployeeAndVerify() async {
    if (!validateEmployeeData()) {
      return false;
    }

    isLoading.value = true;
    error.value = null;
    final result = await createEmployeeUseCase(_formInput());
    isLoading.value = false;

    return result.fold((failure) {
      _showSaveFailure(failure, action: 'crear');
      return false;
    }, _openEmailVerification);
  }

  Future<bool> _openEmailVerification(EmployeeEntity created) async {
    try {
      final verified = await Get.to<bool>(
        () => const VerifyEmployeeEmailScreen(),
        binding: VerifyEmployeeEmailBinding(),
        arguments: {
          'email': created.email,
          'employee_name': created.fullName,
          'employee_id': created.id,
        },
        fullscreenDialog: true,
        preventDuplicates: true,
        transition: Transition.rightToLeft,
        duration: const Duration(milliseconds: 300),
      );

      clearForm();

      if (verified == true) {
        await loadEmployees();
        Get.snackbar(
          'Éxito',
          'Profesional creado y verificado correctamente',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green[100],
          colorText: Colors.green[900],
          duration: const Duration(seconds: 3),
          margin: const EdgeInsets.all(10),
          borderRadius: 10,
          icon: const Icon(Icons.check_circle, color: Colors.green),
        );
        Get.offAllNamed(GetRoutes.employees);
        return true;
      }

      Get.snackbar(
        'Advertencia',
        'El empleado se ha creado pero está inactivo hasta que se verifique su email',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange[100],
        colorText: Colors.orange[900],
        duration: const Duration(seconds: 4),
        margin: const EdgeInsets.all(10),
        borderRadius: 10,
        icon: const Icon(Icons.warning_amber, color: Colors.orange),
      );
      Get.offAllNamed(GetRoutes.employees);
      return false;
    } catch (navigationError) {
      print('Error durante la navegación: $navigationError');
      Get.offAllNamed(GetRoutes.employees);
      return false;
    }
  }

  Future<bool> updateEmployee() async {
    if (!validateEmployeeData(isEdit: true)) {
      return false;
    }

    try {
      isLoading.value = true;
      error.value = null;

      final result = await updateEmployeeUseCase(UpdateEmployeeParams(
        id: editingEmployeeId.value,
        input: _formInput(),
      ));

      return result.fold((failure) {
        _showSaveFailure(failure, action: 'actualizar');
        return false;
      }, (updated) {
        final index =
            employees.indexWhere((e) => e.id == editingEmployeeId.value);
        if (index >= 0) {
          employees[index] = updated;
          filterEmployees();
        }

        clearForm();
        isEditMode.value = false;
        editingEmployeeId.value = '';

        Get.back();
        Get.snackbar(
          'Éxito',
          'Profesional actualizado correctamente',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green[100],
          colorText: Colors.green[900],
          duration: const Duration(seconds: 3),
          icon: const Icon(Icons.check_circle, color: Colors.green),
        );
        return true;
      });
    } finally {
      isLoading.value = false;
      update();
    }
  }

  /// Formulario → datos para el use case (los normaliza y valida él).
  EmployeeInput _formInput() => EmployeeInput(
        name: name.value,
        lastname: lastname.value,
        email: email.value,
        phone: phone.value,
        password: password.value.isEmpty ? null : password.value,
        services: _prepareServiceAssignments(),
        schedule: _prepareSchedule(),
      );

  void _showSaveFailure(Failure failure, {required String action}) {
    error.value = failure.message;
    switch (failure) {
      case DuplicateEmailFailure(:final email):
        _showSpecificErrorDialog(
            title: "Email duplicado",
            icon: Icons.email,
            message: failure.message,
            field: "Email",
            currentValue: email,
            solution: "Por favor utilice otro correo electrónico.");
      case DuplicatePhoneFailure(:final phone):
        _showSpecificErrorDialog(
            title: "Teléfono duplicado",
            icon: Icons.phone_android,
            message: failure.message,
            field: "Teléfono",
            currentValue: phone,
            solution: "Por favor utilice otro número de teléfono.");
      case InvalidEmployeeDataFailure():
        _showFieldError('Revisa los datos', failure.message);
      default:
        Get.snackbar(
          'Error',
          'No se pudo $action el profesional: ${failure.message}',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red[100],
          colorText: Colors.red[900],
          duration: const Duration(seconds: 3),
          icon: const Icon(Icons.error, color: Colors.red),
        );
    }
  }

  /// `false` con el motivo en [error] (p. ej. activar sin el email
  /// verificado: `EmployeeEmailNotVerifiedFailure`).
  Future<bool> toggleEmployeeStatus(String employeeId, bool isActive) async {
    error.value = null;
    final result = await toggleEmployeeStatusUseCase(
        ToggleEmployeeStatusParams(employeeId: employeeId, isActive: isActive));
    return result.fold((failure) {
      error.value = failure.message;
      return false;
    }, (_) => true);
  }

  Future<bool> deleteEmployee(String employeeId, {String? reason}) async {
    try {
      isLoading.value = true;
      error.value = null;

      final result = await deleteEmployeeUseCase(
          DeleteEmployeeParams(employeeId: employeeId, reason: reason));

      return result.fold((failure) {
        error.value = failure.message;
        switch (failure) {
          case NotFoundFailure():
            _showErrorSnackbar('No encontrado',
                'El profesional no existe o ya fue eliminado');
          case NetworkFailure():
            _showErrorSnackbar('Sin conexión',
                'Verifica tu conexión a internet y vuelve a intentar');
          default:
            _showErrorSnackbar('No se pudo eliminar', failure.message);
        }
        return false;
      }, (_) {
        final employeeIndex = employees.indexWhere((e) => e.id == employeeId);
        if (employeeIndex >= 0) {
          final deletedEmployee = employees.removeAt(employeeIndex);
          deletedEmployees.add(
              deletedEmployee.markDeleted(at: DateTime.now(), reason: reason));
          filterEmployees();
          filterDeletedEmployees();
        }

        _showSuccessSnackbar('Profesional eliminado correctamente');
        return true;
      });
    } finally {
      isLoading.value = false;
      update();
    }
  }

  Future<bool> showDeleteEmployeeDialog(EmployeeEntity employee) async {
    final TextEditingController reasonController = TextEditingController();

    final result = await Get.dialog<bool>(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: Get.height * 0.85, // Máximo 85% de la pantalla
            maxWidth: Get.width * 0.9, // Máximo 90% del ancho
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header del diálogo
              Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: const Icon(
                        Icons.delete_outline,
                        color: Colors.orange,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Eliminar Profesional',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // Contenido scrolleable
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Pregunta principal
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: const TextStyle(
                              color: Colors.black87, fontSize: 16),
                          children: [
                            const TextSpan(
                                text: '¿Estás seguro que deseas eliminar a '),
                            TextSpan(
                              text: employee.fullName,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const TextSpan(text: '?'),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Información compacta del soft delete
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border:
                              Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.info_outline,
                                    color: Colors.blue, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Eliminación segura (soft delete)',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: Colors.blue[800],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text('• Se mantiene el historial de citas',
                                style: TextStyle(fontSize: 12)),
                            const Text('• Se conservan los datos para reportes',
                                style: TextStyle(fontSize: 12)),
                            const Text('• Se puede restaurar posteriormente',
                                style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Campo de razón
                      const Text(
                        'Razón (opcional)',
                        style: TextStyle(
                            fontWeight: FontWeight.w500, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: reasonController,
                        decoration: InputDecoration(
                          hintText: 'Ej: Renuncia, despido, fin de contrato...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          hintStyle: const TextStyle(fontSize: 13),
                        ),
                        maxLines: 2,
                        maxLength: 100, // Limitar caracteres
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),

              // Botones en la parte inferior
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Get.back(result: false),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Get.back(result: true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Eliminar',
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: true,
    );

    if (result == true) {
      final reason = reasonController.text.trim();
      return await deleteEmployee(employee.id,
          reason: reason.isNotEmpty ? reason : null);
    }

    return false;
  }

  Future<bool> restoreEmployee(String employeeId) async {
    try {
      isLoadingDeleted.value = true;
      error.value = null;

      final result = await restoreEmployeeUseCase(employeeId);

      return result.fold((failure) {
        error.value = failure.message;
        switch (failure) {
          case NotFoundFailure():
            _showErrorSnackbar(
                'No encontrado', 'El empleado eliminado no fue encontrado');
          case NetworkFailure():
            _showErrorSnackbar(
                'Sin conexión', 'Verifica tu conexión a internet');
          default:
            _showErrorSnackbar('Error al restaurar', failure.message);
        }
        return false;
      }, (restoration) {
        final deletedIndex =
            deletedEmployees.indexWhere((e) => e.id == employeeId);
        EmployeeEntity? restored;
        if (deletedIndex >= 0) {
          restored = deletedEmployees
              .removeAt(deletedIndex)
              .markRestored(isActive: restoration.isActive);
          employees.add(restored);
          filterEmployees();
          filterDeletedEmployees();
        }

        if (restoration.needsEmailVerification) {
          _showSuccessSnackbar(
              'Profesional restaurado. Queda inactivo hasta que verifique su email');
        } else if (restored != null) {
          _showRestoreSuccessSnackbar(restored.fullName);
        } else {
          _showSuccessSnackbar('Profesional restaurado correctamente');
        }
        return true;
      });
    } finally {
      isLoadingDeleted.value = false;
      update();
    }
  }

  Future<bool> showRestoreEmployeeDialog(EmployeeEntity employee) async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.teal.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(
                Icons.restore,
                color: Colors.teal,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Restaurar Profesional',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: const TextStyle(color: Colors.black87, fontSize: 16),
                children: [
                  const TextSpan(text: '¿Deseas restaurar a '),
                  TextSpan(
                    text: employee.fullName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const TextSpan(text: '?'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.teal.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.teal.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline,
                          color: Colors.teal, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'El empleado volverá a estar activo',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                            color: Colors.teal[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                  // const SizedBox(height: 8),
                  // const Text('✅ Aparecerá en la lista de empleados activos',
                  //     style: TextStyle(fontSize: 12)),
                  // const Text('✅ Podrá hacer login nuevamente',
                  //     style: TextStyle(fontSize: 12)),
                  // const Text('✅ Podrá agendar citas',
                  //     style: TextStyle(fontSize: 12)),
                  const SizedBox(height: 8),
                  const Row(
                    children: [
                      Icon(Icons.check_circle, size: 16, color: Colors.green),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Aparecerá en la lista de empleados activos',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Row(
                    children: [
                      Icon(Icons.check_circle, size: 16, color: Colors.green),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Podrá hacer login nuevamente',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Row(
                    children: [
                      Icon(Icons.check_circle, size: 16, color: Colors.green),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Podrá agendar citas',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  if (employee.deletionReason != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Razón original: ${employee.deletionReason}',
                      style: TextStyle(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Get.back(result: false),
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Get.back(result: true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Restaurar',
                      style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (result == true) {
      return await restoreEmployee(employee.id);
    }

    return false;
  }

// Snackbar para mostrar éxito
  void _showSuccessSnackbar(String message) {
    Get.snackbar(
      'Éxito',
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.green.withValues(alpha: 0.9),
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(16),
      borderRadius: 10,
      icon: const Icon(Icons.check_circle, color: Colors.white),
    );
  }

// Snackbar para mostrar errores generales
  void _showErrorSnackbar(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.red.withValues(alpha: 0.9),
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(16),
      borderRadius: 10,
      icon: const Icon(Icons.error_outline, color: Colors.white),
    );
  }

  void _showRestoreSuccessSnackbar(String employeeName) {
    Get.snackbar(
      '♻️ Restaurado',
      '$employeeName ha sido restaurado correctamente',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.teal.withValues(alpha: 0.9),
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(16),
      borderRadius: 10,
      icon: const Icon(Icons.restore, color: Colors.white),
    );
  }

  List<EmployeeEntity> getCurrentEmployeesList() {
    if (showDeletedEmployees.value) {
      return filteredDeletedEmployees.toList();
    }
    return filteredEmployees.toList();
  }

  String getCurrentListTitle() {
    if (showDeletedEmployees.value) {
      return 'Profesionales Eliminados (${filteredDeletedEmployees.length})';
    }
    return 'Profesionales Activos (${filteredEmployees.length})';
  }

  bool getCurrentLoadingState() {
    if (showDeletedEmployees.value) {
      return isLoadingDeleted.value;
    }
    return isLoading.value;
  }

  void switchEmployeeView({required bool showDeleted}) {
    if (showDeleted != showDeletedEmployees.value) {
      showDeletedEmployees.value = showDeleted;

      if (showDeleted && deletedEmployees.isEmpty) {
        loadDeletedEmployees();
      }

      // Limpiar búsqueda al cambiar de vista
      searchQuery.value = '';

      update();
    }
  }

  // Método para cancelar la edición
  void cancelEdit() {
    clearForm();
    isEditMode.value = false;
    editingEmployeeId.value = '';
    update();
  }

  void clearForm() {
    // Limpiar valores reactivos
    name.value = '';
    lastname.value = '';
    email.value = '';
    phone.value = '';
    password.value = '';
    selectedServiceIds.clear();
    serviceCommissions.clear();

    // Limpiar controladores de texto sin disparar listeners
    nameController.text = '';
    lastnameController.text = '';
    emailController.text = '';
    phoneController.text = '';
    passwordController.text = '';

    // Reiniciar el horario
    schedule.clear();

    // Reiniciar los días habilitados (lunes a viernes por defecto)
    initEnabledDays();

    // Inicializar el horario después de reiniciar los días
    initSchedule();

    // Agregar un log para verificar
    print(
        'Formulario limpiado: nombre=${name.value}, apellido=${lastname.value}, email=${email.value}');
    print('Días habilitados después de limpiar: $enabledDays');
    print('Horario después de limpiar: $schedule');

    // Asegurarse de que la UI se actualice
    update();
  }

  List<EmployeeEntity> getActiveEmployees() {
    return employees.where((employee) => employee.isActive).toList();
  }

  // Métodos auxiliares para preparar datos
  Map<String, ServiceAssignment> _prepareServiceAssignments() {
    final Map<String, ServiceAssignment> serviceAssignments = {};
    for (final serviceId in selectedServiceIds) {
      serviceAssignments[serviceId] = ServiceAssignment(
        serviceId: serviceId,
        commissionPercentage: serviceCommissions[serviceId] ?? 0.0,
      );
    }
    return serviceAssignments;
  }

  Map<String, WorkHours> _prepareSchedule() => {
        for (final day in enabledDays)
          if (schedule[day]
              case {'start': final String start, 'end': final String end}
              when start.isNotEmpty && end.isNotEmpty)
            day: WorkHours(start: start, end: end),
      };

  // Método para mostrar un diálogo de error específico con detalles del campo
  void _showSpecificErrorDialog({
    required String title,
    required IconData icon,
    required String message,
    required String field,
    required String currentValue,
    required String solution,
  }) {
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(icon, color: Colors.red[700], size: 28),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[800],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Campo: $field",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.red[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Valor actual: $currentValue",
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              solution,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[800],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text(
              'Entendido',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      barrierDismissible: false,
    );
  }

  // Método auxiliar para mostrar diálogo de confirmación
  Future<bool> _showConfirmationDialog({
    required String title,
    required String message,
    String confirmText = 'Confirmar',
    String cancelText = 'Cancelar',
    Color confirmColor = Colors.red,
    IconData icon = Icons.warning_amber_rounded,
  }) async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        title: Row(
          children: [
            Icon(icon, color: confirmColor),
            const SizedBox(width: 10),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(
              cancelText,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text(
              confirmText,
              style:
                  TextStyle(color: confirmColor, fontWeight: FontWeight.bold),
            ),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      barrierDismissible: false,
    );

    return result ?? false;
  }

  // Métodos para verificación específica por campo
  bool isNameValid() {
    return name.value.trim().isNotEmpty;
  }

  bool isLastnameValid() {
    return lastname.value.trim().isNotEmpty;
  }

  bool isEmailValid() {
    return email.value.trim().isNotEmpty &&
        GetUtils.isEmail(email.value.trim());
  }

  bool isPhoneValid() {
    return phone.value.trim().isNotEmpty && phone.value.trim().length >= 7;
  }

  bool isPasswordValid({bool isEdit = false}) {
    if (isEdit && password.value.isEmpty) {
      return true; // En modo edición, contraseña vacía es válida
    }
    return password.value.length >= 8;
  }

  bool areServicesSelected() {
    return selectedServiceIds.isNotEmpty;
  }

  bool isDayScheduleEnabled() {
    return enabledDays.isNotEmpty;
  }

  // Método para confirmar antes de abandonar la página de edición
  Future<bool> confirmDiscard() async {
    // Si no hay cambios, no preguntar
    if (name.value.isEmpty &&
        lastname.value.isEmpty &&
        email.value.isEmpty &&
        phone.value.isEmpty) {
      return true;
    }

    return await _showConfirmationDialog(
      title: 'Descartar cambios',
      message: '¿Está seguro que desea descartar los cambios realizados?',
      confirmText: 'Descartar',
      cancelText: 'Continuar editando',
      confirmColor: Colors.orange,
      icon: Icons.warning,
    );
  }

  // Método para confirmar antes de eliminar un empleado
  Future<bool> confirmDelete(String employeeName) async {
    return await _showConfirmationDialog(
      title: 'Eliminar profesional',
      message:
          '¿Está seguro que desea eliminar a $employeeName?\n\nEsta acción no se puede deshacer.',
      confirmText: 'Eliminar',
      cancelText: 'Cancelar',
      confirmColor: Colors.red,
      icon: Icons.delete_forever,
    );
  }

  // Método para confirmar antes de cambiar el estado de un empleado
  Future<bool> confirmStatusChange(String employeeName, bool newStatus) async {
    final action = newStatus ? 'activar' : 'desactivar';
    return await _showConfirmationDialog(
      title: '${newStatus ? 'Activar' : 'Desactivar'} profesional',
      message: '¿Está seguro que desea $action a $employeeName?',
      confirmText: 'Confirmar',
      cancelText: 'Cancelar',
      confirmColor: newStatus ? Colors.green : Colors.orange,
      icon: newStatus ? Icons.check_circle : Icons.person_off,
    );
  }
}
