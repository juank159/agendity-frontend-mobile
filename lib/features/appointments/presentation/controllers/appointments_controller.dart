import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/routes/routes.dart';
import 'package:login_signup/features/appointments/domain/repositories/appointments_repository.dart';

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

// Nuevas importaciones para la funcionalidad de suscripción
import 'package:login_signup/features/subscriptions/domain/usecases/check_subscription_status_usecase.dart';
import 'package:login_signup/features/subscriptions/presentation/screens/subscription_plans_screen.dart';
import 'package:login_signup/features/subscriptions/presentation/bindings/subscription_binding.dart';

class AppointmentsController extends GetxController {
  final AppointmentsRepository appointmentsRepository;
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

  // Nuevo estado para guardar el rol del usuario
  final RxString userRole = ''.obs;
  final RxString userId = ''.obs;

  // Servicio de suscripciones
  late CheckSubscriptionStatusUseCase? checkSubscriptionStatusUseCase;
  final RxBool canCreateAppointment = true.obs;
  final RxString subscriptionMessage = ''.obs;

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
      this.appointmentsRepository,
      {this.checkSubscriptionStatusUseCase}) {
    _initializeControllers();
    _getUserInfo();
    _initializeCalendar();
    _loadInitialData();

    // Intentar obtener el servicio de suscripción si no fue inyectado
    if (checkSubscriptionStatusUseCase == null) {
      try {
        checkSubscriptionStatusUseCase =
            Get.find<CheckSubscriptionStatusUseCase>();
      } catch (e) {
        print('No se encontró CheckSubscriptionStatusUseCase: $e');
      }
    }
  }

  Future<bool> checkSubscriptionStatus() async {
    try {
      print('Verificando estado de suscripción...');

      if (checkSubscriptionStatusUseCase == null) {
        print(
            'CheckSubscriptionStatusUseCase es null, intentando encontrarlo...');
        try {
          checkSubscriptionStatusUseCase =
              Get.find<CheckSubscriptionStatusUseCase>();
          print('CheckSubscriptionStatusUseCase encontrado con éxito');
        } catch (e) {
          print('No se pudo encontrar CheckSubscriptionStatusUseCase: $e');
          return true; // Por defecto, permitir si no se puede verificar
        }
      }

      if (checkSubscriptionStatusUseCase == null) {
        print('CheckSubscriptionStatusUseCase sigue siendo null');
        return true;
      }

      print('Llamando a checkSubscriptionStatusUseCase...');
      final result = await checkSubscriptionStatusUseCase!.call();
      print('Respuesta de CheckSubscriptionStatusUseCase: $result');

      canCreateAppointment.value = result['canCreateAppointment'] ?? true;
      subscriptionMessage.value = result['message'] ?? '';

      print('Estado de suscripción: ${canCreateAppointment.value}');
      print('Mensaje: ${subscriptionMessage.value}');

      // Guardar el mensaje para el diálogo
      if (!canCreateAppointment.value && result['message'] != null) {
        subscriptionMessage.value = result['message'];
      }

      return canCreateAppointment.value;
    } catch (e) {
      print('Error verificando estado de suscripción: $e');
      return true; // Por defecto, permitir si hay un error
    }
  }

  void _showSubscriptionRequiredDialog() {
    print('Mostrando diálogo de suscripción requerida');

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.workspace_premium,
                  color: Colors.orange[700],
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Plan de prueba finalizado',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                subscriptionMessage.value.isNotEmpty
                    ? subscriptionMessage.value
                    : 'Has alcanzado el límite de citas de tu plan de prueba. Adquiere un plan para continuar.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Get.back(); // Cerrar diálogo

                    // Navegación directa a la pantalla de planes
                    Get.toNamed(GetRoutes.subscriptionPlans);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(Get.context!).primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Ver planes disponibles',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Get.back(); // Solo cerrar el diálogo
                },
                child: Text(
                  'Cancelar',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: true,
    );
  }

  // Nuevo método para obtener la info del usuario
  Future<void> _getUserInfo() async {
    try {
      final token = await localStorage.getToken();
      if (token != null) {
        // Extraer la información del token
        final parts = token.split('.');
        if (parts.length == 3) {
          final payload = json.decode(
            utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
          );

          // Extraer roles y ID del usuario
          final roles = payload['roles'];
          userId.value = payload['id'] ?? '';

          if (roles is List) {
            if (roles.contains('Owner')) {
              userRole.value = 'Owner';
            } else if (roles.contains('Employee')) {
              userRole.value = 'Employee';
            }
          } else if (roles is String) {
            userRole.value = roles;
          }

          print('Rol de usuario detectado: ${userRole.value}');
          print('ID de usuario: ${userId.value}');
        }
      }
    } catch (e) {
      print('Error al obtener información del usuario: $e');
    }
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

      // Imprimir detalle de cada cita para diagnóstico
      for (int i = 0; i < result.length; i++) {
        print('---------- Cita #${i + 1} ----------');
        print('ID: ${result[i].id}');
        print('Professional ID: ${result[i].professionalId}');
        print('Client: ${result[i].clientName}');
        print('Date: ${result[i].startTime}');
      }

      print('ID del usuario actual: ${userId.value}');

      // MODIFICACIÓN: Filtrar citas según el rol del usuario
      List<AppointmentEntity> filteredAppointments = [];

      if (userRole.value == 'Owner') {
        // Si es Owner, mostrar todas las citas
        filteredAppointments = result;
        print('Rol Owner: Mostrando todas las citas (${result.length})');
      } else if (userRole.value == 'Employee') {
        // Si es Employee, mostrar solo las citas donde él es el profesional
        filteredAppointments = result.where((appointment) {
          print(
              'Comparando: appointment.professionalId=${appointment.professionalId} con userId=${userId.value}');
          return appointment.professionalId == userId.value;
        }).toList();

        print(
            'Rol Employee: Filtrando citas para el profesional ${userId.value}');
        print(
            'Citas filtradas: ${filteredAppointments.length} de ${result.length}');
      } else {
        // Por defecto, mostrar todas las citas
        filteredAppointments = result;
        print('Rol no especificado: Mostrando todas las citas por defecto');
      }

      // Asignar las citas filtradas
      appointments.assignAll(filteredAppointments);

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
    _getUserInfo(); // Obtener información del usuario
    _initializeCalendar();
    _loadInitialData();
  }

  Future<void> createAppointment({
    required String clientId,
    required DateTime startTime,
    String? notes,
  }) async {
    try {
      // Verificar estado de suscripción primero
      final canContinue = await checkSubscriptionStatus();
      if (!canContinue) {
        _showSubscriptionRequiredDialog();
        return;
      }

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

      print("DEBUG - Hora local al crear: $startTime");

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

        // Verificar si es un error de límite de suscripción
        bool isSubscriptionLimitReached = false;

        if (apiError is AppointmentException) {
          // Usar la nueva propiedad de AppointmentException
          if (apiError.isSubscriptionLimitReached) {
            isSubscriptionLimitReached = true;
          }
        } else if (apiError is DioException) {
          final responseData = apiError.response?.data;
          final statusCode = apiError.response?.statusCode;

          print('DioException - statusCode: $statusCode');
          print('DioException - responseData: $responseData');

          if (statusCode == 400 &&
              responseData is Map &&
              responseData['message'] != null) {
            final message = responseData['message'].toString().toLowerCase();
            if (message.contains('límite de citas') ||
                message.contains('adquiere un plan')) {
              isSubscriptionLimitReached = true;
            }
          }
        }

        // También verificar en el mensaje de error general
        if (!isSubscriptionLimitReached) {
          final errorMessage = apiError.toString().toLowerCase();
          if (errorMessage.contains('límite de citas') ||
              errorMessage.contains('adquiere un plan')) {
            isSubscriptionLimitReached = true;
          }
        }

        // Si es un error de límite de suscripción, mostrar diálogo
        if (isSubscriptionLimitReached) {
          print('ERROR DETECTADO: Límite de suscripción - Mostrando diálogo');
          _showSubscriptionRequiredDialog();
          return;
        }

        // Verificar si es un error de horario no disponible
        bool isHorarioNoDisponible = false;

        if (apiError is AppointmentException &&
            apiError.isHorarioNoDisponible) {
          isHorarioNoDisponible = true;
        } else {
          // Verificación de texto para cualquier tipo de error
          if (apiError
              .toString()
              .toLowerCase()
              .contains('horario no disponible')) {
            isHorarioNoDisponible = true;
          }
        }

        // Mostrar el diálogo si es un error de horario no disponible
        if (isHorarioNoDisponible) {
          print('ERROR DETECTADO: Horario no disponible - Mostrando diálogo');
          _showHorarioNoDisponibleDialog();
          return;
        }

        // Si no es un error de horario ni de suscripción, propagarlo
        throw apiError;
      }
    } catch (e) {
      print('=== ERROR EN CONTROLLER ===');
      print('Error final: $e');
      error.value = e.toString();

      // Verificar una última vez si contiene mensajes específicos
      final errorMessage = e.toString().toLowerCase();

      if (errorMessage.contains('límite de citas') ||
          errorMessage.contains('adquiere un plan')) {
        print('ERROR DETECTADO: Límite de suscripción - Mostrando diálogo');
        _showSubscriptionRequiredDialog();
        return;
      }

      if (errorMessage.contains('horario no disponible')) {
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
    String? clientId,
    String? totalPrice, // Mantenerlo como parámetro para recibirlo
  }) async {
    try {
      // Verificar estado de suscripción primero
      final canContinue = await checkSubscriptionStatus();
      if (!canContinue) {
        _showSubscriptionRequiredDialog();
        return;
      }

      isLoading.value = true;
      error.value = null;

      // DIAGNÓSTICO: Mostrar todos los datos recibidos
      print('\n🔍 ===== INICIO ACTUALIZACIÓN CITA =====');
      print('📝 DATOS RECIBIDOS:');
      print('ID: $appointmentId');
      print('Profesional: $professionalId');
      print('Servicios: $serviceIds');
      print('Hora: $startTime');
      print('Notas: $notes');
      print('Cliente ID: $clientId');
      print('Precio Total: $totalPrice'); // Solo para debug

      // Buscar cita actual para comparación
      final currentAppointment =
          appointments.firstWhereOrNull((a) => a.id == appointmentId);
      if (currentAppointment == null) {
        throw Exception(
            'No se pudo encontrar la cita ID: $appointmentId en la lista cargada');
      }

      // Construir payload para la API - Asegurarse que todos los campos necesarios estén incluidos
      final Map<String, dynamic> updateData = {
        'professional_id': professionalId,
        'service_ids': serviceIds,
        'date': startTime.toIso8601String(),
        'notes': notes ?? '',
      };

      // Añadir client_id solo si fue proporcionado
      if (clientId != null && clientId.isNotEmpty) {
        updateData['client_id'] = clientId;
      }

      // NO añadir total_price porque el backend no lo acepta

      print('\n📦 PAYLOAD A ENVIAR:');
      print(json.encode(updateData));

      // Hacer la llamada a la API
      final result =
          await Get.find<AppointmentsRepository>().updateAppointmentDirect(
        appointmentId: appointmentId,
        data: updateData,
      );

      print('\n✅ RESPUESTA RECIBIDA:');
      print('Éxito: ${result != null}');
      if (result != null) {
        print('Cliente actualizado: ${result.clientName}');
        print('Profesional actualizado: ${result.professionalId}');
        print('Servicios actualizados: ${result.serviceTypes}');
        print('Hora actualizada: ${result.startTime}');
      }

      // Limpiar estado
      selectedServiceIds.clear();
      this.totalPrice.value = 0;

      // Recargar citas
      await _reloadAppointmentsForDay(startTime);

      Get.snackbar(
        'Éxito',
        'Cita actualizada correctamente',
        backgroundColor: Colors.green[100],
        colorText: Colors.green[800],
        duration: const Duration(seconds: 3),
      );

      update(['calendar-view']);
    } catch (e) {
      print('\n❌ ERROR GENERAL:');
      print('Tipo: ${e.runtimeType}');
      print('Mensaje: $e');

      error.value = e.toString();

      if (e.toString().toLowerCase().contains('horario no disponible')) {
        _showHorarioNoDisponibleDialog();
      } else {
        Get.snackbar(
          'Error',
          'No se pudo actualizar la cita: ${_formatErrorMessage(e)}',
          backgroundColor: Colors.red[100],
          colorText: Colors.red[800],
          duration: const Duration(seconds: 4),
        );
      }
      throw e;
    } finally {
      print('\n🏁 ===== FIN ACTUALIZACIÓN CITA =====\n');
      isLoading.value = false;
    }
  }

  // Método para encontrar ID de cliente por nombre
  String _findClientIdByName(String clientName) {
    final clientMatch = clients.firstWhereOrNull((c) =>
        '${c['name']} ${c['lastname'] ?? ''}'.trim() == clientName.trim());

    if (clientMatch != null) {
      print('📍 Cliente encontrado por nombre: ${clientMatch['id']}');
      return clientMatch['id'];
    }

    print('⚠️ No se encontró cliente con nombre: "$clientName"');
    return '';
  }

  // Método auxiliar para extraer el Tenant ID del token JWT
  String _extractTenantId(String token) {
    try {
      final parts = token.split('.');
      if (parts.length > 1) {
        final payload = base64Url.normalize(parts[1]);
        final decoded = utf8.decode(base64Url.decode(payload));
        final Map<String, dynamic> data = jsonDecode(decoded);
        final tenantId = data['tenant_id'] ?? '';
        return tenantId;
      }
    } catch (e) {
      print('Error extrayendo tenant_id: $e');
    }
    return '';
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

  String sanitizeString(String input) {
    if (input.isEmpty) return input;

    try {
      // Convertir a UTF-8 y volver a UTF-16 para validar
      List<int> bytes = utf8.encode(input);
      utf8.decode(bytes);
      return input;
    } catch (e) {
      print('⚠️ UTF-16 ERROR: Detectado texto mal formado: "$input"');
      // Elimina emojis y otros caracteres problemáticos
      final pattern = RegExp(
          r'[\u{1F600}-\u{1F64F}]|[\u{1F300}-\u{1F5FF}]|[\u{1F680}-\u{1F6FF}]|[\u{2600}-\u{26FF}]|[\u{2700}-\u{27BF}]',
          unicode: true);
      return input.replaceAll(pattern, '?');
    }
  }
}
