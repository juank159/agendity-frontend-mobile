import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/features/appointments/data/repositories/appointments_repository_impl.dart';
import 'package:login_signup/shared/local_storage/local_storage.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:login_signup/features/appointments/data/datasources/appointment_data_source.dart';
import 'package:login_signup/features/appointments/data/models/appointment_model.dart';
import 'package:login_signup/features/appointments/domain/entities/appointment_entity.dart';
import 'package:login_signup/features/appointments/domain/usescases/create_appointment_usecase.dart';
import 'package:login_signup/features/appointments/domain/usescases/delete_appointment_usecase.dart';
import 'package:login_signup/features/appointments/domain/usescases/get_appointments_usecase.dart';
import 'package:login_signup/features/appointments/domain/usescases/update_appointment_usecase.dart';
import 'package:login_signup/features/clients/data/datasources/clients_remote_datasource.dart';
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

  // Estado observable
  final RxList<AppointmentEntity> appointments = <AppointmentEntity>[].obs;
  final RxList<Map<String, dynamic>> services = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> clients = <Map<String, dynamic>>[].obs;
  final Rx<DateTime> selectedDate = DateTime.now().obs;
  final RxBool isLoading = false.obs;
  final Rx<String?> error = Rx<String?>(null);
  final Rx<CalendarView> currentView = CalendarView.month.obs;
  final Rx<EmployeeEntity?> selectedEmployee = Rx<EmployeeEntity?>(null);

  // Nuevo estado para manejar múltiples servicios seleccionados
  final RxList<String> selectedServiceIds = <String>[].obs;
  final RxDouble totalPrice = 0.0.obs;

  AppointmentsController(
    this.getAppointmentsUseCase,
    this.createAppointmentUseCase,
    this.updateAppointmentUseCase,
    this.deleteAppointmentUseCase,
    this.servicesDataSource,
    this.clientsDataSource,
    this.localStorage,
  ) {
    _initializeCalendar();
    _loadInitialData();
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
    if (error is DioException) {
      if (error.response?.statusCode == 500) {
        return 'Error del servidor. Por favor, contacta al soporte técnico.';
      }
      if (error.response?.data != null) {
        final data = error.response?.data;
        if (data is Map && data['message'] != null) {
          return data['message'].toString();
        }
      }
      return 'Error de conexión. Por favor, verifica tu conexión a internet.';
    }
    if (error is AppointmentException) {
      return error.message;
    }
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

      final appointment = AppointmentModel.create(
        serviceIds: selectedServiceIds.toList(),
        clientId: clientId,
        professionalId: selectedEmployee.value!.id,
        ownerId: ownerId,
        startTime: startTime,
        totalPrice: totalPrice.value.toString(),
        notes: notes ?? '',
      );

      final createdAppointment = await createAppointmentUseCase(appointment);

      // Limpiar la selección
      selectedServiceIds.clear();
      totalPrice.value = 0;

      // Construir las fechas de inicio y fin del día
      final startDate = DateTime(
        startTime.year,
        startTime.month,
        startTime.day,
      );
      final endDate = DateTime(
        startTime.year,
        startTime.month,
        startTime.day,
        23,
        59,
        59,
      );

      print('Recargando citas después de crear:');
      print('Inicio: $startDate');
      print('Fin: $endDate');

      // Primero actualizamos la fecha seleccionada
      selectedDate.value = startTime;

      // Forzamos limpieza de la lista actual de citas
      appointments.clear();

      // Esperamos a que se complete la recarga de citas
      await fetchAppointments(
        startDate: startDate,
        endDate: endDate,
      );

      // Verificamos que la nueva cita esté en la lista
      print('Total de citas después de recargar: ${appointments.length}');

      // Notificamos el éxito después de la recarga
      Get.snackbar(
        'Éxito',
        'Cita creada correctamente',
        backgroundColor: Colors.green[100],
        colorText: Colors.green[800],
        duration: const Duration(seconds: 3),
      );

      // Forzamos una actualización del calendario
      update(['calendar-view']);
    } catch (e) {
      print('=== ERROR EN CONTROLLER ===');
      print('Error: $e');
      error.value = e.toString();
      Get.snackbar(
        'Error',
        'No se pudo crear la cita: ${e.toString()}',
        backgroundColor: Colors.red[100],
        colorText: Colors.red[800],
        duration: const Duration(seconds: 4),
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> selectEmployee(EmployeeEntity employee) async {
    selectedEmployee.value = employee;
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
    selectedServiceIds.clear();
    totalPrice.value = 0;
    super.onClose();
  }
}
