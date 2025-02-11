import 'dart:convert';
import 'package:get/get.dart';
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
import 'package:login_signup/shared/local_storage/local_storage.dart';

class AppointmentsController extends GetxController {
  final GetAppointmentsUseCase getAppointmentsUseCase;
  final CreateAppointmentUseCase createAppointmentUseCase;
  final UpdateAppointmentUseCase updateAppointmentUseCase;
  final DeleteAppointmentUseCase deleteAppointmentUseCase;
  final ServicesRemoteDataSource servicesDataSource;
  final ClientsRemoteDataSource clientsDataSource;

  final RxList<AppointmentEntity> appointments = <AppointmentEntity>[].obs;
  final RxList<Map<String, dynamic>> services = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> clients = <Map<String, dynamic>>[].obs;
  final Rx<DateTime> selectedDate = DateTime.now().obs;
  final RxBool isLoading = false.obs;
  final Rx<String?> error = Rx<String?>(null);
  final Rx<CalendarView> currentView = CalendarView.month.obs;
  final Rx<EmployeeEntity?> selectedEmployee = Rx<EmployeeEntity?>(null);

  AppointmentsController(
    this.getAppointmentsUseCase,
    this.createAppointmentUseCase,
    this.updateAppointmentUseCase,
    this.deleteAppointmentUseCase,
    this.servicesDataSource,
    this.clientsDataSource,
  ) {
    _initializeCalendar();
    _loadInitialData();
  }

  void _initializeCalendar() {
    currentView.value = CalendarView.month;
    final now = DateTime.now();
    selectedDate.value = now;

    // Cargar las citas del mes actual
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
    }
  }

  Future<void> loadClients() async {
    try {
      final result = await clientsDataSource.getClients();
      clients.assignAll(result);
    } catch (e) {
      print('Error loading clients: $e');
    }
  }

  void changeView(CalendarView view) {
    print('Cambiando vista de ${currentView.value} a $view');

    // Cambiar la vista
    currentView.value = view;

    // Usar la fecha actual cuando cambiamos de vista
    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate;

    switch (view) {
      case CalendarView.day:
        // Asegurarnos de usar la fecha actual al cambiar a vista diaria
        selectedDate.value = now; // Actualizar la fecha seleccionada
        startDate = DateTime(now.year, now.month, now.day);
        endDate = startDate.add(const Duration(days: 1));
        print('Vista día: ${startDate.toString()} - ${endDate.toString()}');
        break;

      case CalendarView.week:
        // Calcular el inicio de la semana actual
        selectedDate.value = now; // Actualizar la fecha seleccionada
        startDate = now.subtract(Duration(days: now.weekday - 1));
        endDate = startDate.add(const Duration(days: 7));
        print('Vista semana: ${startDate.toString()} - ${endDate.toString()}');
        break;

      case CalendarView.month:
      default:
        // Para la vista mensual, usar el mes actual completo
        selectedDate.value = now; // Actualizar la fecha seleccionada
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        print('Vista mes: ${startDate.toString()} - ${endDate.toString()}');
        break;
    }

    // Asegurarnos de que las citas se carguen después de que la vista se haya actualizado
    Future.microtask(() {
      fetchAppointments(
        startDate: startDate,
        endDate: endDate,
      );
    });

    // Forzar actualización de la UI
    update();
  }

  void _loadDataForCurrentView() {
    if (isLoading.value) return;

    DateTime startDate;
    DateTime endDate;
    final now = selectedDate.value;

    switch (currentView.value) {
      case CalendarView.day:
        startDate = DateTime(now.year, now.month, now.day);
        endDate = startDate.add(const Duration(days: 1));
        print('Cargando vista diaria: $startDate - $endDate');
        break;

      case CalendarView.week:
        startDate = now.subtract(Duration(days: now.weekday - 1));
        endDate = startDate.add(const Duration(days: 7));
        print('Cargando vista semanal: $startDate - $endDate');
        break;

      case CalendarView.month:
      default:
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        print('Cargando vista mensual: $startDate - $endDate');
        break;
    }

    fetchAppointments(startDate: startDate, endDate: endDate);
  }

  void onViewChanged(ViewChangedDetails details) {
    if (details.visibleDates.isEmpty) return;

    // Actualizar la fecha seleccionada sin cambiar inmediatamente la vista
    final middleDate = details.visibleDates[details.visibleDates.length ~/ 2];

    // Solo cargar nuevas citas si la fecha realmente cambió
    if (selectedDate.value.day != middleDate.day ||
        selectedDate.value.month != middleDate.month ||
        selectedDate.value.year != middleDate.year) {
      selectedDate.value = middleDate;

      // No hacer la llamada si ya está cargando
      if (!isLoading.value) {
        DateTime startDate;
        DateTime endDate;

        switch (currentView.value) {
          case CalendarView.day:
            startDate =
                DateTime(middleDate.year, middleDate.month, middleDate.day);
            endDate = startDate.add(const Duration(days: 1));
            break;

          case CalendarView.week:
            startDate =
                middleDate.subtract(Duration(days: middleDate.weekday - 1));
            endDate = startDate.add(const Duration(days: 7));
            break;

          case CalendarView.month:
          default:
            startDate = DateTime(middleDate.year, middleDate.month, 1);
            endDate =
                DateTime(middleDate.year, middleDate.month + 1, 0, 23, 59, 59);
            break;
        }

        fetchAppointments(startDate: startDate, endDate: endDate);
      }
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

      final utcStartDate = startDate?.toUtc();
      final utcEndDate = endDate?.toUtc();

      print('Consultando citas para rango:');
      print('Inicio: ${utcStartDate?.toLocal()}');
      print('Fin: ${utcEndDate?.toLocal()}');

      final result = await getAppointmentsUseCase(
        startDate: utcStartDate,
        endDate: utcEndDate,
      );

      appointments.assignAll(result);
      print('Citas cargadas: ${result.length}');
    } catch (e) {
      error.value = e.toString();
      print('Error cargando citas: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> createAppointment({
    required String serviceId,
    required String clientId,
    required DateTime startTime,
    String? notes,
  }) async {
    try {
      isLoading.value = true;
      error.value = null;

      final service = services.firstWhere(
        (s) => s['id'].toString() == serviceId,
        orElse: () => throw Exception('Servicio no encontrado'),
      );

      if (selectedEmployee.value == null) {
        throw Exception('Debe seleccionar un profesional');
      }

      final storage = Get.find<LocalStorage>();
      final token = await storage.getToken();
      final tokenParts = token!.split('.');
      final payload = json.decode(
        utf8.decode(base64Url.decode(base64Url.normalize(tokenParts[1]))),
      );
      final ownerId = payload['id'];

      final appointment = AppointmentModel.create(
        serviceId: serviceId,
        clientId: clientId,
        professionalId: selectedEmployee.value!.id,
        ownerId: ownerId,
        startTime: startTime,
        totalPrice: service['price']?.toString() ?? '0',
        notes: notes ?? '',
      );

      await createAppointmentUseCase(appointment);
      _loadDataForCurrentView();

      Get.snackbar('Éxito', 'Cita creada correctamente');
    } catch (e) {
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
}
