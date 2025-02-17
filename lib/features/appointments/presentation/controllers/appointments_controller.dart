import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
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
    currentView.value = CalendarView.month;
    final now = DateTime.now();
    selectedDate.value = now;

    fetchAppointments(
      startDate: DateTime(now.year, now.month, 1),
      endDate: DateTime(now.year, now.month + 1, 0, 23, 59, 59),
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
    _updateTotalPrice();
  }

  // Método para actualizar el precio total
  void _updateTotalPrice() {
    double total = 0.0;
    for (String serviceId in selectedServiceIds) {
      final service = services.firstWhere(
        (s) => s['id'].toString() == serviceId,
        orElse: () => {'price': 0},
      );
      total += double.parse(service['price']?.toString() ?? '0');
    }
    totalPrice.value = total;
  }

  void changeView(CalendarView view) {
    print('Cambiando vista de ${currentView.value} a $view');
    currentView.value = view;

    // Siempre usar la fecha y hora actual
    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate;

    switch (view) {
      case CalendarView.day:
        // Para vista diaria, siempre usar el día actual
        startDate = DateTime(now.year, now.month, now.day);
        endDate = startDate.add(const Duration(days: 1));
        // Actualizar la fecha seleccionada a la actual
        selectedDate.value = now;
        print(
            'Vista día: Mostrando ${startDate.toString()} a ${endDate.toString()}');
        break;

      case CalendarView.week:
        // Para vista semanal, calcular desde el inicio de la semana actual
        startDate = now.subtract(Duration(days: now.weekday - 1));
        endDate = startDate.add(const Duration(days: 7));
        selectedDate.value = now;
        print(
            'Vista semana: Mostrando ${startDate.toString()} a ${endDate.toString()}');
        break;

      case CalendarView.month:
      default:
        // Para vista mensual, mostrar el mes actual completo
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        selectedDate.value = now;
        print(
            'Vista mes: Mostrando ${startDate.toString()} a ${endDate.toString()}');
        break;
    }

    // Cargar las citas inmediatamente
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

    if (selectedDate.value.day != middleDate.day ||
        selectedDate.value.month != middleDate.month ||
        selectedDate.value.year != middleDate.year) {
      selectedDate.value = middleDate;

      // Cargar citas inmediatamente al cambiar la fecha visible
      _loadDataForCurrentView();
    }
  }

  Future<void> fetchAppointments({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (isLoading.value) return;

    try {
      isLoading.value = true;
      error.value = null;

      print('Consultando citas para rango:');
      print('Fecha inicio original: ${startDate?.toString()}');
      print('Fecha fin original: ${endDate?.toString()}');

      final result = await getAppointmentsUseCase(
        startDate: startDate,
        endDate: endDate,
      );

      print('Citas obtenidas del servidor: ${result.length}');
      result.forEach((appointment) {
        print('Cita: ${appointment.startTime} - ${appointment.endTime}');
      });

      appointments.assignAll(result);
    } catch (e) {
      print('Error detallado: $e');
      if (e is DioException) {
        print('DioError data: ${e.response?.data}');
        print('DioError status code: ${e.response?.statusCode}');
      }
      error.value = _formatErrorMessage(e);
    } finally {
      isLoading.value = false;
    }
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

      await createAppointmentUseCase(appointment);
      _loadDataForCurrentView();

      Get.snackbar('Éxito', 'Cita creada correctamente');
    } catch (e) {
      print('=== ERROR EN CONTROLLER ===');
      print('Error: $e');
      error.value = e.toString();
      Get.snackbar('Error', 'No se pudo crear la cita: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> selectEmployee(EmployeeEntity employee) async {
    selectedEmployee.value = employee;
  }

  CalendarDataSource getCalendarDataSource() =>
      AppointmentDataSource(appointments);

  @override
  void onClose() {
    selectedServiceIds.clear();
    totalPrice.value = 0;
    super.onClose();
  }
}
