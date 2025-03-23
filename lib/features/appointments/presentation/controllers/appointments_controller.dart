import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:login_signup/features/employees/domain/usecases/create_employee_usecase.dart';
import 'package:login_signup/features/employees/domain/usecases/get_employee_by_id_usecase.dart';
import 'package:login_signup/features/employees/domain/usecases/get_employees_usecase.dart';
import 'package:login_signup/shared/local_storage/local_storage.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

import 'package:login_signup/features/appointments/data/repositories/appointments_repository_impl.dart';
import 'package:login_signup/features/appointments/data/datasources/appointment_data_source.dart';
import 'package:login_signup/features/appointments/data/models/appointment_model.dart';
import 'package:login_signup/features/appointments/domain/entities/appointment_entity.dart';
import 'package:login_signup/features/appointments/domain/usescases/create_appointment_usecase.dart';
import 'package:login_signup/features/appointments/domain/usescases/delete_appointment_usecase.dart';
import 'package:login_signup/features/appointments/domain/usescases/get_appointments_usecase.dart';
import 'package:login_signup/features/appointments/domain/usescases/update_appointment_usecase.dart';

import 'package:login_signup/features/clients/data/datasources/clients_remote_datasource.dart';

import 'package:login_signup/features/employees/presentation/controllers/employees_controller.dart';
import 'package:login_signup/features/employees/domain/entities/employee_entity.dart';

import 'package:login_signup/features/services/data/datasources/services_remote_datasource.dart';

class AppointmentsController extends GetxController {
  final GetAppointmentsUseCase getAppointmentsUseCase;
  final CreateAppointmentUseCase createAppointmentUseCase;
  final UpdateAppointmentUseCase updateAppointmentUseCase;
  final DeleteAppointmentUseCase deleteAppointmentUseCase;
  final ServicesRemoteDataSource servicesDataSource;
  final ClientsRemoteDataSource clientsDataSource;
  final LocalStorage localStorage;

  // Cambiar la referencia directa a una propiedad que se puede reinicializar
  Rx<EmployeeEntity?> selectedEmployee = Rx<EmployeeEntity?>(null);

  // Estado observable
  final RxList<AppointmentEntity> appointments = <AppointmentEntity>[].obs;
  final RxList<Map<String, dynamic>> services = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> clients = <Map<String, dynamic>>[].obs;
  final Rx<DateTime> selectedDate = DateTime.now().obs;
  final RxBool isLoading = false.obs;
  final Rx<String?> error = Rx<String?>(null);
  final Rx<CalendarView> currentView = CalendarView.month.obs;

  // Nuevo estado para manejar múltiples servicios seleccionados
  final RxList<String> selectedServiceIds = <String>[].obs;
  final RxDouble totalPrice = 0.0.obs;

  EmployeesController? _employeesController;

  EmployeesController? get employeesController {
    if (_employeesController == null) {
      try {
        _employeesController = Get.find<EmployeesController>();
      } catch (e) {
        print('Error al obtener EmployeesController: $e');
        try {
          // Intentar crear un nuevo controlador
          _employeesController = EmployeesController();
          Get.put(_employeesController!);
        } catch (innerError) {
          print('No se pudo crear EmployeesController: $innerError');
        }
      }
    }
    return _employeesController;
  }

  AppointmentsController(
    this.getAppointmentsUseCase,
    this.createAppointmentUseCase,
    this.updateAppointmentUseCase,
    this.deleteAppointmentUseCase,
    this.servicesDataSource,
    this.clientsDataSource,
    this.localStorage,
  ) {
    _initializeControllers();
    _initializeCalendar();
    _loadInitialData();
  }

  void _initializeControllers() {
    try {
      // Intentar conseguir el EmployeesController, pero manejar si no está disponible
      _employeesController = Get.find<EmployeesController>();
    } catch (e) {
      print('EmployeesController no disponible: $e');
      // Intentar inicializar EmployeesController
      _initializeEmployeesController();
    }
  }

  void _initializeEmployeesController() {
    try {
      // Intentar registrar un nuevo controlador directamente
      _employeesController = EmployeesController();
      Get.put(_employeesController!);
      print('EmployeesController inicializado manualmente');
    } catch (e) {
      print('No se pudo inicializar EmployeesController: $e');
      // Si falla, intenta crear uno con dependencias explícitas
      try {
        final getEmployeesUseCase = Get.find<GetEmployeesUseCase>();
        final getEmployeeByIdUseCase = Get.find<GetEmployeeByIdUseCase>();
        final createEmployeeUseCase = Get.find<CreateEmployeeUseCase>();

        _employeesController = EmployeesController(
            getEmployeesUseCase: getEmployeesUseCase,
            getEmployeeByIdUseCase: getEmployeeByIdUseCase,
            createEmployeeUseCase: createEmployeeUseCase);

        Get.put(_employeesController!);
      } catch (innerError) {
        print(
            'Error al crear EmployeesController con dependencias explícitas: $innerError');
      }
    }
  }

  void _initializeCalendar() {
    currentView.value = CalendarView.day; // Comenzar en vista diaria
    final now = DateTime.now();
    selectedDate.value = now;

    // Cargar citas del día actual
    fetchAppointments(
      startDate: DateTime(now.year, now.month, now.day),
      endDate: DateTime(now.year, now.month, now.day, 23, 59, 59),
    );
  }

  Future<void> _loadInitialData() async {
    try {
      isLoading.value = true;
      await Future.wait([
        loadServices(),
        loadClients(),
      ]);
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadServices() async {
    try {
      final result = await servicesDataSource.getServices();
      services.assignAll(result);
    } catch (e) {
      print('Error loading services: $e');
      error.value = e.toString();
    }
  }

  Future<void> loadClients() async {
    try {
      final result = await clientsDataSource.getClients();
      clients.assignAll(result);
    } catch (e) {
      print('Error loading clients: $e');
      error.value = e.toString();
    }
  }

  // Nuevo método para manejar la selección de servicios
  void toggleServiceSelection(String serviceId) {
    if (selectedServiceIds.contains(serviceId)) {
      selectedServiceIds.remove(serviceId);
    } else {
      selectedServiceIds.add(serviceId);
    }
    updateTotalPrice();
  }

  void updateTotalPrice() {
    double total = 0.0;
    for (String serviceId in selectedServiceIds) {
      final service = services.firstWhere(
        (s) => s['id'].toString() == serviceId,
        orElse: () => {'price': 0},
      );
      total += double.parse(service['price']?.toString() ?? '0');
    }
    totalPrice.value = total;
    update([
      'services-summary'
    ]); // Esto actualiza cualquier widget que dependa de los servicios
  }

  void changeView(CalendarView view, {DateTime? targetDate}) {
    print('Cambiando vista de ${currentView.value} a $view');

    final now = DateTime.now();
    DateTime selectedDateTime;

    // Determinar la fecha y hora a usar
    if (targetDate != null) {
      // Si se proporciona una fecha específica, usar la hora actual
      selectedDateTime = DateTime(targetDate.year, targetDate.month,
          targetDate.day, now.hour, now.minute);
    } else {
      // Si no hay fecha específica, usar fecha y hora actual
      selectedDateTime = now;
    }

    // Actualizar la vista actual
    currentView.value = view;
    selectedDate.value = selectedDateTime;

    DateTime startDate;
    DateTime endDate;

    switch (view) {
      case CalendarView.day:
        startDate = DateTime(selectedDateTime.year, selectedDateTime.month,
            selectedDateTime.day);
        endDate = DateTime(selectedDateTime.year, selectedDateTime.month,
            selectedDateTime.day, 23, 59, 59);
        print('Vista día: ${startDate.toString()} - ${endDate.toString()}');
        break;

      case CalendarView.week:
      case CalendarView.workWeek:
        // Obtener el inicio de la semana (lunes)
        startDate = selectedDateTime
            .subtract(Duration(days: selectedDateTime.weekday - 1));
        startDate = DateTime(startDate.year, startDate.month, startDate.day);
        // Fin de semana (domingo)
        endDate = startDate
            .add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
        print('Vista semana: ${startDate.toString()} - ${endDate.toString()}');
        break;

      case CalendarView.month:
      default:
        startDate = DateTime(selectedDateTime.year, selectedDateTime.month, 1);
        endDate = DateTime(
            selectedDateTime.year, selectedDateTime.month + 1, 0, 23, 59, 59);
        print('Vista mes: ${startDate.toString()} - ${endDate.toString()}');
        break;
    }

    print('Consultando citas para el rango:');
    print('Inicio: $startDate');
    print('Fin: $endDate');

    fetchAppointments(
      startDate: startDate,
      endDate: endDate,
    );

    update();
  }

  void _loadDataForCurrentView() {
    final now = selectedDate.value;
    DateTime startDate;
    DateTime endDate;

    switch (currentView.value) {
      case CalendarView.day:
        startDate = DateTime(now.year, now.month, now.day);
        endDate = startDate.add(const Duration(days: 1));
        break;

      case CalendarView.week:
        startDate = now.subtract(Duration(days: now.weekday - 1));
        endDate = startDate.add(const Duration(days: 7));
        break;

      case CalendarView.month:
      default:
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        break;
    }

    fetchAppointments(startDate: startDate, endDate: endDate);
  }

  void onViewChanged(ViewChangedDetails details) {
    if (details.visibleDates.isEmpty) return;

    final middleDate = details.visibleDates[details.visibleDates.length ~/ 2];
    final now = DateTime.now();

    // Inicializar con valores por defecto
    DateTime startDate =
        DateTime(middleDate.year, middleDate.month, middleDate.day);
    DateTime endDate =
        DateTime(middleDate.year, middleDate.month, middleDate.day, 23, 59, 59);
    bool needsUpdate = false;

    print('Evaluando cambio de vista: ${currentView.value}');
    print('Fecha actual seleccionada: ${selectedDate.value}');
    print('Nueva fecha media: $middleDate');

    switch (currentView.value) {
      case CalendarView.day:
        // Para vista diaria, siempre actualizar al deslizar
        if (selectedDate.value.day != middleDate.day ||
            selectedDate.value.month != middleDate.month ||
            selectedDate.value.year != middleDate.year) {
          startDate =
              DateTime(middleDate.year, middleDate.month, middleDate.day);
          endDate = DateTime(
              middleDate.year, middleDate.month, middleDate.day, 23, 59, 59);
          needsUpdate = true;
          print('Deslizamiento en vista día: ${startDate.toString()}');
        }
        break;

      case CalendarView.week:
      case CalendarView.workWeek:
        final currentWeekStart = selectedDate.value
            .subtract(Duration(days: selectedDate.value.weekday - 1));
        final newWeekStart =
            middleDate.subtract(Duration(days: middleDate.weekday - 1));

        if (currentWeekStart.day != newWeekStart.day ||
            currentWeekStart.month != newWeekStart.month) {
          startDate =
              DateTime(newWeekStart.year, newWeekStart.month, newWeekStart.day);
          endDate = startDate.add(
              const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
          needsUpdate = true;
          print(
              'Deslizamiento en vista semana: ${startDate.toString()} - ${endDate.toString()}');
        }
        break;

      case CalendarView.month:
      case CalendarView.timelineDay:
      case CalendarView.timelineWeek:
      case CalendarView.timelineWorkWeek:
      case CalendarView.timelineMonth:
      case CalendarView.schedule:
        if (selectedDate.value.month != middleDate.month ||
            selectedDate.value.year != middleDate.year) {
          startDate = DateTime(middleDate.year, middleDate.month, 1);
          endDate =
              DateTime(middleDate.year, middleDate.month + 1, 0, 23, 59, 59);
          needsUpdate = true;
          print(
              'Deslizamiento en vista mes: ${startDate.toString()} - ${endDate.toString()}');
        }
        break;
    }

    if (needsUpdate) {
      print('Actualizando vista con nuevo rango:');
      print('Inicio: $startDate');
      print('Fin: $endDate');

      selectedDate.value = middleDate;
      fetchAppointments(
        startDate: startDate,
        endDate: endDate,
      );
    }
  }

  Future<void> fetchAppointments({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      isLoading.value = true;
      error.value = null;

      final localStartDate = startDate?.toLocal();
      final localEndDate = endDate?.toLocal();

      print('Consultando citas:');
      print('Inicio: ${localStartDate?.toString()}');
      print('Fin: ${localEndDate?.toString()}');

      final result = await getAppointmentsUseCase(
        startDate: localStartDate,
        endDate: localEndDate,
      );

      print('Citas obtenidas: ${result.length}');
      result.forEach((appointment) {
        print('Cita: ${appointment.startTime} - ${appointment.endTime}');
      });

      // Aseguramos que la lista se actualice correctamente
      appointments.assignAll(result);

      // Forzamos actualización del calendario después de cargar las citas
      update(['calendar-view']);
    } catch (e) {
      print('Error al cargar citas: $e');
      error.value = _formatErrorMessage(e);
    } finally {
      isLoading.value = false;
    }
  }

  List<String> getSelectedServiceNames() {
    return selectedServiceIds
        .map((id) =>
            services
                .firstWhereOrNull((s) => s['id'].toString() == id)?['name']
                ?.toString() ??
            '')
        .where((name) => name.isNotEmpty)
        .toList();
  }

  String _formatErrorMessage(dynamic error) {
    if (error is AppointmentException) {
      if (error.message == 'Horario no disponible') {
        return 'El horario seleccionado no está disponible para este profesional';
      }
      return error.message;
    }

    if (error is DioException) {
      // Errores HTTP comunes
      switch (error.response?.statusCode) {
        case 400:
          return 'Solicitud incorrecta. Por favor, verifica los datos.';
        case 401:
          return 'No autorizado. Por favor, inicia sesión nuevamente.';
        case 403:
          return 'Acceso denegado.';
        case 404:
          return 'Recurso no encontrado.';
        case 500:
          return 'Error del servidor. Por favor, contacta al soporte técnico.';
        default:
          return 'Error de conexión. Por favor, verifica tu conexión a internet.';
      }
    }

    // Para otros tipos de errores, devolvemos el mensaje tal cual
    return error.toString();
  }

  @override
  void onInit() {
    super.onInit();
    print('AppointmentsController onInit');
    _initializeCalendar();
    _loadInitialData();
  }

  Future<void> createAppointment({
    required String clientId,
    required DateTime startTime,
    String? notes,
  }) async {
    try {
      // Verificaciones existentes...
      if (employeesController == null) {
        throw Exception('El controlador de empleados no está disponible');
      }

      if (selectedServiceIds.isEmpty) {
        throw Exception('Debe seleccionar al menos un servicio');
      }

      if (selectedEmployee.value == null) {
        throw Exception('Debe seleccionar un profesional');
      }

      isLoading.value = true;
      error.value = null;

      final ownerId = await localStorage.getUserId();
      if (ownerId == null) {
        throw Exception('No se pudo obtener el ID del usuario');
      }

      print('=== DEBUG DATOS ANTES DE CREAR CITA ===');
      print('Client ID: $clientId');
      print('Professional ID: ${selectedEmployee.value?.id}');
      print('Service IDs: $selectedServiceIds');
      print('Owner ID: $ownerId');
      print('Start Time: $startTime');
      print('Notes: $notes');

      print('DEBUG - Hora local al crear: $startTime');

      // Calcular duración total de los servicios seleccionados
      int totalDurationMinutes = 0;
      for (String serviceId in selectedServiceIds) {
        final service = services.firstWhere((s) => s['id'] == serviceId,
            orElse: () => {'duration': 30});
        totalDurationMinutes +=
            int.parse((service['duration'] ?? 30).toString());
      }

      // Calcular hora de finalización prevista
      final endTime = startTime.add(Duration(minutes: totalDurationMinutes));
      print(
          'Hora de finalización prevista: $endTime (duración: $totalDurationMinutes min)');

      final appointment = AppointmentModel.create(
        serviceIds: selectedServiceIds.toList(),
        clientId: clientId,
        professionalId: selectedEmployee.value!.id,
        ownerId: ownerId,
        startTime: startTime,
        totalPrice: totalPrice.value.toString(),
        notes: notes ?? '',
      );

      try {
        final createdAppointment = await createAppointmentUseCase(appointment);

        // La cita se creó exitosamente
        selectedServiceIds.clear();
        totalPrice.value = 0;

        // Recargar citas para el día actual
        await _reloadAppointmentsForDay(startTime);

        Get.snackbar(
          'Éxito',
          'Cita creada correctamente',
          backgroundColor: Colors.green[100],
          colorText: Colors.green[800],
          duration: const Duration(seconds: 3),
        );

        update(['calendar-view']);
      } catch (apiError) {
        print('=== ERROR AL CREAR CITA ===');
        print('Error tipo: ${apiError.runtimeType}');
        print('Error detalle: $apiError');

        // Buscar el error de horario no disponible de varias maneras
        bool isHorarioNoDisponible = false;

        if (apiError is DioException) {
          final responseData = apiError.response?.data;
          final statusCode = apiError.response?.statusCode;

          print('DioException - statusCode: $statusCode');
          print('DioException - responseData: $responseData');

          // Verificar respuesta de DioException
          if (statusCode == 400 &&
              responseData is Map &&
              responseData['message'] == 'Horario no disponible') {
            isHorarioNoDisponible = true;
          }
        } else if (apiError is AppointmentException) {
          print('AppointmentException - message: ${apiError.message}');

          // Verificar AppointmentException
          if (apiError.message.contains('Horario no disponible')) {
            isHorarioNoDisponible = true;
          }
        }

        // Verificación de texto para cualquier tipo de error
        if (!isHorarioNoDisponible &&
            apiError
                .toString()
                .toLowerCase()
                .contains('horario no disponible')) {
          isHorarioNoDisponible = true;
        }

        // Mostrar el diálogo si es un error de horario no disponible
        if (isHorarioNoDisponible) {
          print('ERROR DETECTADO: Horario no disponible - Mostrando diálogo');
          _showHorarioNoDisponibleDialog();
          return;
        }

        // Si no es un error de horario, propagarlo
        throw apiError;
      }
    } catch (e) {
      print('=== ERROR EN CONTROLLER ===');
      print('Error final: $e');
      error.value = e.toString();

      // Verificar una última vez si contiene el mensaje de horario no disponible
      if (e.toString().toLowerCase().contains('horario no disponible')) {
        _showHorarioNoDisponibleDialog();
      } else {
        // Mostrar error genérico
        Get.snackbar(
          'Error',
          'No se pudo crear la cita: ${_formatErrorMessage(e)}',
          backgroundColor: Colors.red[100],
          colorText: Colors.red[800],
          duration: const Duration(seconds: 4),
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

// Método auxiliar para recargar las citas del día
  Future<void> _reloadAppointmentsForDay(DateTime date) async {
    // Construir las fechas de inicio y fin del día
    final startDate = DateTime(
      date.year,
      date.month,
      date.day,
    );
    final endDate = DateTime(
      date.year,
      date.month,
      date.day,
      23,
      59,
      59,
    );

    // Actualizar la fecha seleccionada
    selectedDate.value = date;

    // Forzar limpieza de la lista actual de citas
    appointments.clear();

    // Recargar citas
    await fetchAppointments(
      startDate: startDate,
      endDate: endDate,
    );
  }

  // Función para mostrar el diálogo personalizado
  void _showHorarioNoDisponibleDialog() {
    print('Mostrando diálogo de horario no disponible');

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icono de horario
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.schedule,
                  color: Colors.orange[700],
                  size: 48,
                ),
              ),
              const SizedBox(height: 16),
              // Título
              Text(
                'Horario no disponible',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 12),
              // Mensaje
              Text(
                'El profesional ${selectedEmployee.value?.name} ${selectedEmployee.value?.lastname} no está disponible en este horario.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Por favor, selecciona otra hora o elige otro profesional.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              // Solo un botón para cerrar el diálogo
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Get.back(); // Cerrar solo el diálogo, no el formulario
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(Get.context!).primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                  child: const Text(
                    'Entendido',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  Future<void> selectEmployee(EmployeeEntity employee) async {
    if (employeesController != null) {
      selectedEmployee.value = employee;
    } else {
      Get.snackbar(
        'Error',
        'No se pudo seleccionar el empleado',
        backgroundColor: Colors.red[100],
        colorText: Colors.red[800],
      );
    }
  }

  Future<void> updateAppointment({
    required String appointmentId,
    required String professionalId,
    required List<String> serviceIds,
    required DateTime startTime,
    String? notes,
  }) async {
    try {
      isLoading.value = true;
      error.value = null;

      // Buscar la cita en la lista de citas cargadas
      final currentAppointment =
          appointments.firstWhereOrNull((a) => a.id == appointmentId);
      if (currentAppointment == null) {
        throw Exception('No se pudo encontrar la cita a actualizar');
      }

      // Calcular duración total de los servicios seleccionados
      int totalDurationMinutes = 0;
      for (String serviceId in serviceIds) {
        final service = services.firstWhere(
          (s) => s['id'] == serviceId,
          orElse: () => {'duration': 30},
        );
        totalDurationMinutes +=
            int.parse((service['duration'] ?? 30).toString());
      }

      // Calcular hora de finalización prevista
      final endTime = startTime.add(Duration(minutes: totalDurationMinutes));

      print('=== DEBUG DATOS ANTES DE ACTUALIZAR CITA ===');
      print('Appointment ID: $appointmentId');
      print('Professional ID: $professionalId');
      print('Service IDs: $serviceIds');
      print('Start Time: $startTime');
      print('End Time (calculada): $endTime');
      print('Duración total: $totalDurationMinutes minutos');
      print('Notes: $notes');

      // Determinar clientId
      // Si es una instancia de AppointmentModel, usamos su clientId directamente
      String clientId = '';

      if (currentAppointment is AppointmentModel) {
        clientId = currentAppointment.clientId;
      } else {
        // Si no, tratamos de obtenerlo de alguna otra manera
        // Por ejemplo, buscar en nuestro repositorio de clientes por el nombre
        final client = clients.firstWhereOrNull(
            (c) => c['name'] == currentAppointment.clientName);
        if (client != null) {
          clientId = client['id'];
        } else {
          throw Exception('No se pudo determinar el ID del cliente');
        }
      }

      // Crear el modelo para actualización
      final appointment = AppointmentModel(
        id: appointmentId,
        title: currentAppointment.title,
        clientName: currentAppointment.clientName,
        startTime: startTime,
        endTime: endTime,
        serviceTypes: currentAppointment.serviceTypes,
        status: currentAppointment.status,
        totalPrice: currentAppointment.totalPrice,
        clientId: clientId,
        serviceIds: serviceIds,
        professionalId: professionalId,
        ownerId: currentAppointment.ownerId,
        paymentStatus: currentAppointment.paymentStatus,
        notes: notes ?? currentAppointment.notes,
        colors: currentAppointment.colors?.cast<String>(),
      );

      // Llamar al caso de uso para actualizar la cita
      await updateAppointmentUseCase(appointment);

      // Limpiar la selección
      selectedServiceIds.clear();
      totalPrice.value = 0;

      // Recargar citas del día
      await _reloadAppointmentsForDay(startTime);

      // Get.snackbar(
      //   'Éxito',
      //   'Cita actualizada correctamente',
      //   backgroundColor: Colors.green[100],
      //   colorText: Colors.green[800],
      //   duration: const Duration(seconds: 3),
      // );

      update(['calendar-view']);
    } catch (e) {
      print('=== ERROR AL ACTUALIZAR CITA ===');
      print('Error tipo: ${e.runtimeType}');
      print('Error detalle: $e');

      error.value = e.toString();

      // Verificar si es un error de horario no disponible
      if (e.toString().toLowerCase().contains('horario no disponible')) {
        _showHorarioNoDisponibleDialog();
      } else {
        // Mostrar error genérico
        Get.snackbar(
          'Error',
          'No se pudo actualizar la cita: ${_formatErrorMessage(e)}',
          backgroundColor: Colors.red[100],
          colorText: Colors.red[800],
          duration: const Duration(seconds: 4),
        );
      }
      throw e; // Re-lanzar para que el formulario pueda manejar el error
    } finally {
      isLoading.value = false;
    }
  }

  CalendarDataSource getCalendarDataSource() {
    print('Creando calendar data source con ${appointments.length} citas');
    return AppointmentDataSource(appointments);
  }

  void onDaySelected(DateTime date) {
    selectedDate.value = date;
    changeView(CalendarView.day, targetDate: date);
  }

  @override
  void onClose() {
    _employeesController = null;
    selectedServiceIds.clear();
    totalPrice.value = 0;
    super.onClose();
  }
}
