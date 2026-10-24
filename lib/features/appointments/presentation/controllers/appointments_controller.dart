import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/session/session_repository.dart';
import 'package:login_signup/shared/controller/session_controller.dart';
import 'package:login_signup/core/routes/routes.dart';
import 'package:login_signup/features/appointments/domain/repositories/appointments_repository.dart';

import 'package:login_signup/features/employees/domain/usecases/create_employee_usecase.dart';
import 'package:login_signup/features/employees/domain/usecases/get_employee_by_id_usecase.dart';
import 'package:login_signup/features/employees/domain/usecases/get_employees_usecase.dart';
import 'package:login_signup/shared/local_storage/local_storage.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:login_signup/features/auth/presentation/controllers/user_info_controller.dart';

import 'package:login_signup/features/appointments/data/repositories/appointments_repository_impl.dart';
import 'package:login_signup/features/appointments/data/datasources/appointment_data_source.dart';
import 'package:login_signup/features/appointments/data/models/appointment_model.dart';
import 'package:login_signup/features/appointments/domain/entities/appointment_entity.dart';
import 'package:login_signup/features/appointments/domain/usescases/create_appointment_usecase.dart';
import 'package:login_signup/features/appointments/domain/usescases/delete_appointment_usecase.dart';
import 'package:login_signup/features/appointments/domain/usescases/get_appointments_usecase.dart';
import 'package:login_signup/features/appointments/domain/usescases/update_appointment_usecase.dart';

import 'package:login_signup/features/clients/domain/usecases/clients_usecases.dart';
import 'package:login_signup/features/clients/domain/entities/client_entity.dart';

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
  final GetClientsUseCase getClientsUseCase;
  final GetClientsPaginatedUseCase getClientsPaginatedUseCase;
  final LocalStorage localStorage;

  // Cambiar la referencia directa a una propiedad que se puede reinicializar
  Rx<EmployeeEntity?> selectedEmployee = Rx<EmployeeEntity?>(null);

  // Estado observable
  final RxList<AppointmentEntity> appointments = <AppointmentEntity>[].obs;
  final RxList<Map<String, dynamic>> services = <Map<String, dynamic>>[].obs;
  
  // ✅ PAGINACIÓN REAL DEL SERVIDOR PARA CLIENTES
  final RxList<ClientEntity> clients = <ClientEntity>[].obs;
  final RxString clientSearchQuery = ''.obs;
  final RxBool isClientsLoading = false.obs;
  final RxBool isLoadingMoreClients = false.obs;
  
  // ✅ VARIABLES DE PAGINACIÓN DE CLIENTES
  final RxInt clientsCurrentPage = 1.obs;
  final RxInt clientsPageSize = 20.obs; // Para búsqueda de clientes en appointments
  final RxBool hasMoreClients = false.obs;
  
  // ✅ CACHE DE BÚSQUEDA PARA OPTIMIZACIÓN
  String _lastSearchQuery = '';
  final Map<String, List<ClientEntity>> _clientSearchCache = {};
  static const int _maxCacheEntries = 10;
  
  final Rx<DateTime> selectedDate = DateTime.now().obs;
  final RxBool isLoading = false.obs;
  final Rx<String?> error = Rx<String?>(null);
  final Rx<CalendarView> currentView = CalendarView.month.obs;

  // Cache inteligente para optimizar cargas
  final Map<String, List<AppointmentEntity>> _appointmentsCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const int _cacheExpirationMinutes = 5;

  // Nuevo estado para manejar múltiples servicios seleccionados
  final RxList<String> selectedServiceIds = <String>[].obs;
  final RxDouble totalPrice = 0.0.obs;

  // Nuevo estado para guardar el rol del usuario
  final RxString userRole = ''.obs;
  Worker? _sessionWorker;
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
          _employeesController = EmployeesController(
              getEmployeesUseCase: Get.find(),
              getEmployeeByIdUseCase: Get.find(),
              createEmployeeUseCase: Get.find(),
              updateEmployeeUseCase: Get.find(),
              deleteEmployeeUseCase: Get.find(),
              toggleEmployeeStatusUseCase: Get.find(),
              restoreEmployeeUseCase: Get.find(),
              getDeletedEmployeesUseCase: Get.find());

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
      this.getClientsUseCase,
      this.getClientsPaginatedUseCase,
      this.localStorage,
      this.appointmentsRepository,
      {this.checkSubscriptionStatusUseCase}) {
    _initializeControllers();
    _getUserInfo();
    _initializeCalendar();
    _loadInitialData();
    
    // ✅ CONFIGURAR BÚSQUEDA REACTIVA CON DEBOUNCE OPTIMIZADO PARA EL SERVIDOR
    debounce(clientSearchQuery, (_) => _searchClientsFromServer(), time: const Duration(milliseconds: 800));

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

      // Verificar si es un error relacionado con la suscripción
      final errorMessage = e.toString().toLowerCase();

      if (errorMessage.contains('límite de citas') ||
          errorMessage.contains('plan de prueba') ||
          errorMessage.contains('trial')) {
        canCreateAppointment.value = false;

        // Extraer el mensaje para mostrarlo en el diálogo correspondiente
        final message = e.toString();
        final cleanMessage =
            message.contains(':') ? message.split(':').last.trim() : message;
        subscriptionMessage.value =
            cleanMessage.replaceAll(RegExp(r'\(Code: \d+\)'), '').trim();

        return false;
      } else if (errorMessage.contains('suscripción no está activa') ||
          errorMessage.contains('actualiza tu plan')) {
        canCreateAppointment.value = false;

        // Extraer el mensaje para mostrarlo en el diálogo correspondiente
        final message = e.toString();
        final cleanMessage =
            message.contains(':') ? message.split(':').last.trim() : message;
        subscriptionMessage.value =
            cleanMessage.replaceAll(RegExp(r'\(Code: \d+\)'), '').trim();

        return false;
      }

      return true; // Por defecto, permitir si hay un error no relacionado con suscripción
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

  /// Rol e id del usuario desde la sesión de la UI (sin decodificar el JWT).
  /// Se mantiene sincronizado si la sesión cambia (login con otro usuario).
  void _getUserInfo() {
    final session = Get.find<SessionController>();
    void apply(Session? current) {
      userId.value = current?.userId ?? '';
      userRole.value = current == null
          ? ''
          : current.isOwner
              ? 'Owner'
              : current.hasRole(SessionRole.employee)
                  ? 'Employee'
                  : '';
    }

    apply(session.session.value);
    _sessionWorker = ever<Session?>(session.session, apply);
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
      _employeesController = EmployeesController(
          getEmployeesUseCase: Get.find(),
          getEmployeeByIdUseCase: Get.find(),
          createEmployeeUseCase: Get.find(),
          updateEmployeeUseCase: Get.find(),
          deleteEmployeeUseCase: Get.find(),
          toggleEmployeeStatusUseCase: Get.find(),
          restoreEmployeeUseCase: Get.find(),
          getDeletedEmployeesUseCase: Get.find());

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
            createEmployeeUseCase: createEmployeeUseCase,
            updateEmployeeUseCase: Get.find(),
            deleteEmployeeUseCase: Get.find(),
            toggleEmployeeStatusUseCase: Get.find(),
            restoreEmployeeUseCase: Get.find(),
            getDeletedEmployeesUseCase: Get.find());

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

    // Solo cargar citas del día actual (optimización inicial)
    print('🎯 Inicializando calendario con vista diaria - solo día actual');
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

  // ✅ NUEVO MÉTODO: CARGAR CLIENTES CON PAGINACIÓN REAL DEL SERVIDOR
  Future<void> loadClients() async {
    try {
      print('🔄 AppointmentsController: Cargando clientes con paginación del servidor...');
      isClientsLoading.value = true;
      clientsCurrentPage.value = 1;

      final result = await getClientsPaginatedUseCase.execute(
        page: clientsCurrentPage.value,
        limit: clientsPageSize.value,
        search: clientSearchQuery.value.isNotEmpty ? clientSearchQuery.value : null,
      );

      // ✅ ACTUALIZAR VARIABLES DE PAGINACIÓN
      hasMoreClients.value = result.hasNextPage;
      
      // ✅ REEMPLAZAR LOS CLIENTES (PRIMERA PÁGINA)
      clients.assignAll(result.data);
      
      print('✅ Clientes cargados: ${result.data.length}');
      print('📊 Total en servidor: ${result.total}');
      print('📊 Página ${result.page}/${result.totalPages}');
      print('📊 Tiene más: ${result.hasNextPage}');

    } catch (e) {
      print('❌ Error loading clients: $e');
      error.value = e.toString();
    } finally {
      isClientsLoading.value = false;
    }
  }

  // ✅ NUEVO MÉTODO: BÚSQUEDA EN EL SERVIDOR CON DEBOUNCE Y CACHE OPTIMIZADO
  Future<void> _searchClientsFromServer() async {
    // ✅ OPTIMIZACIÓN: Evitar búsquedas vacías o muy cortas
    final query = clientSearchQuery.value.trim();
    if (query.length > 0 && query.length < 2) {
      print('🔍 Búsqueda muy corta, esperando más caracteres...');
      return;
    }
    
    // ✅ OPTIMIZACIÓN: Evitar búsquedas duplicadas
    if (isClientsLoading.value) {
      print('🔍 Búsqueda ya en progreso, ignorando...');
      return;
    }
    
    // ✅ OPTIMIZACIÓN: Verificar cache de búsqueda
    if (_lastSearchQuery == query && _clientSearchCache.containsKey(query)) {
      print('🔍 Usando cache para búsqueda: "$query"');
      clients.assignAll(_clientSearchCache[query]!);
      return;
    }
    
    print('🔍 Iniciando búsqueda optimizada para: "$query"');
    _lastSearchQuery = query;
    clientsCurrentPage.value = 1; // Resetear a la primera página
    await loadClients(); // Cargar con el nuevo criterio de búsqueda
    
    // ✅ GUARDAR EN CACHE (máximo 10 entradas)
    if (query.isNotEmpty && clients.isNotEmpty) {
      if (_clientSearchCache.length >= _maxCacheEntries) {
        _clientSearchCache.remove(_clientSearchCache.keys.first);
      }
      _clientSearchCache[query] = List.from(clients);
    }
  }

  // ✅ CARGAR MÁS CLIENTES (SIGUIENTE PÁGINA)
  Future<void> loadMoreClients() async {
    if (!hasMoreClients.value || isLoadingMoreClients.value) return;

    try {
      isLoadingMoreClients.value = true;
      clientsCurrentPage.value++;

      final result = await getClientsPaginatedUseCase.execute(
        page: clientsCurrentPage.value,
        limit: clientsPageSize.value,
        search: clientSearchQuery.value.isNotEmpty ? clientSearchQuery.value : null,
      );

      // ✅ ACTUALIZAR VARIABLES DE PAGINACIÓN
      hasMoreClients.value = result.hasNextPage;
      
      // ✅ AÑADIR MÁS CLIENTES A LA LISTA EXISTENTE
      clients.addAll(result.data);
      
      print('✅ Más clientes cargados: ${result.data.length}');
      print('📊 Total clientes en memoria: ${clients.length}');

    } catch (e) {
      print('❌ Error cargando más clientes: $e');
      clientsCurrentPage.value--; // Revertir incremento en caso de error
    } finally {
      isLoadingMoreClients.value = false;
    }
  }

  // ✅ Método público para actualizar la búsqueda
  void updateClientSearch(String query) {
    clientSearchQuery.value = query;
  }

  // ✅ Método para limpiar la búsqueda CON CACHE
  void clearClientSearch() {
    clientSearchQuery.value = '';
    _lastSearchQuery = '';
    // ✅ OPTIMIZACIÓN: Limpiar cache al limpiar búsqueda
    _clientSearchCache.clear();
    print('🔍 Cache de búsqueda limpiado');
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
    print('🔄 Cambiando vista de ${currentView.value} a $view');

    final now = DateTime.now();
    DateTime selectedDateTime;

    // Determinar la fecha y hora a usar
    if (targetDate != null) {
      selectedDateTime = DateTime(targetDate.year, targetDate.month,
          targetDate.day, now.hour, now.minute);
    } else {
      selectedDateTime = now;
    }

    // Actualizar la vista actual
    currentView.value = view;
    selectedDate.value = selectedDateTime;

    // Usar el método optimizado para obtener el rango
    final dateRange = _getOptimizedDateRange(view, selectedDateTime);
    final startDate = dateRange['start']!;
    final endDate = dateRange['end']!;

    print('📊 Vista $view optimizada:');
    print('📅 Rango: ${startDate.toString()} - ${endDate.toString()}');

    // Usar fetchAppointments con el rango optimizado
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
    bool needsUpdate = false;

    print('📍 Evaluando cambio de vista: ${currentView.value}');
    print('📅 Fecha actual: ${selectedDate.value}');
    print('📅 Nueva fecha: $middleDate');

    // Verificar si necesitamos actualizar según la vista
    switch (currentView.value) {
      case CalendarView.day:
        // Para vista diaria, actualizar solo si cambia el día
        needsUpdate = selectedDate.value.day != middleDate.day ||
            selectedDate.value.month != middleDate.month ||
            selectedDate.value.year != middleDate.year;
        break;

      case CalendarView.week:
      case CalendarView.workWeek:
        // Para vista semanal, actualizar solo si cambia la semana
        final currentWeekStart = selectedDate.value
            .subtract(Duration(days: selectedDate.value.weekday - 1));
        final newWeekStart =
            middleDate.subtract(Duration(days: middleDate.weekday - 1));
        
        needsUpdate = currentWeekStart.day != newWeekStart.day ||
            currentWeekStart.month != newWeekStart.month ||
            currentWeekStart.year != newWeekStart.year;
        break;

      case CalendarView.month:
      default:
        // Para vista mensual, actualizar solo si cambia el mes
        needsUpdate = selectedDate.value.month != middleDate.month ||
            selectedDate.value.year != middleDate.year;
        break;
    }

    if (needsUpdate) {
      print('🔄 Actualizando vista con optimización');
      selectedDate.value = middleDate;
      
      // Usar el método optimizado que incluye caché
      final dateRange = _getOptimizedDateRange(currentView.value, middleDate);
      
      fetchAppointments(
        startDate: dateRange['start'],
        endDate: dateRange['end'],
      );
    } else {
      print('✅ No se necesita actualización - usando datos existentes');
    }
  }

  // Método para generar clave de caché
  String _generateCacheKey(DateTime? startDate, DateTime? endDate) {
    final start = startDate?.toIso8601String() ?? 'null';
    final end = endDate?.toIso8601String() ?? 'null';
    final role = userRole.value.isNotEmpty ? userRole.value : 'unknown';
    final user = userId.value.isNotEmpty ? userId.value : 'unknown';
    return '${start}_${end}_${role}_${user}';
  }

  // Método para verificar si el caché es válido
  bool _isCacheValid(String cacheKey) {
    if (!_appointmentsCache.containsKey(cacheKey) || 
        !_cacheTimestamps.containsKey(cacheKey)) {
      return false;
    }
    
    final cacheTime = _cacheTimestamps[cacheKey]!;
    final now = DateTime.now();
    final difference = now.difference(cacheTime).inMinutes;
    
    return difference < _cacheExpirationMinutes;
  }

  // Método para limpiar caché expirado
  void _cleanExpiredCache() {
    final now = DateTime.now();
    final expiredKeys = <String>[];
    
    _cacheTimestamps.forEach((key, timestamp) {
      if (now.difference(timestamp).inMinutes >= _cacheExpirationMinutes) {
        expiredKeys.add(key);
      }
    });
    
    for (final key in expiredKeys) {
      _appointmentsCache.remove(key);
      _cacheTimestamps.remove(key);
    }
  }

  // Método para invalidar caché cuando se modifican las citas
  void _invalidateCache() {
    print('🗑️ Invalidando caché de citas');
    _appointmentsCache.clear();
    _cacheTimestamps.clear();
  }

  // Método para invalidar caché de un rango específico
  void _invalidateCacheForDate(DateTime date) {
    final keysToRemove = <String>[];
    
    _cacheTimestamps.keys.forEach((key) {
      // Si la clave contiene la fecha afectada, invalidarla
      if (key.contains(date.toIso8601String().substring(0, 10))) {
        keysToRemove.add(key);
      }
    });
    
    for (final key in keysToRemove) {
      _appointmentsCache.remove(key);
      _cacheTimestamps.remove(key);
      print('🗑️ Cache invalidado para: $key');
    }
  }

  // Método optimizado para calcular rangos mínimos según la vista
  Map<String, DateTime> _getOptimizedDateRange(CalendarView view, DateTime selectedDate) {
    DateTime startDate;
    DateTime endDate;
    
    switch (view) {
      case CalendarView.day:
        // Solo el día actual
        startDate = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
        endDate = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 23, 59, 59);
        break;
        
      case CalendarView.week:
      case CalendarView.workWeek:
        // Solo la semana actual
        final weekStart = selectedDate.subtract(Duration(days: selectedDate.weekday - 1));
        startDate = DateTime(weekStart.year, weekStart.month, weekStart.day);
        endDate = startDate.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
        break;
        
      case CalendarView.month:
      default:
        // Solo el mes actual
        startDate = DateTime(selectedDate.year, selectedDate.month, 1);
        endDate = DateTime(selectedDate.year, selectedDate.month + 1, 0, 23, 59, 59);
        break;
    }
    
    return {'start': startDate, 'end': endDate};
  }

  Future<void> fetchAppointments({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      isLoading.value = true;
      error.value = null;

      // Si no se especifican fechas, usar el rango optimizado según la vista actual
      if (startDate == null || endDate == null) {
        final dateRange = _getOptimizedDateRange(currentView.value, selectedDate.value);
        startDate = dateRange['start'];
        endDate = dateRange['end'];
      }

      final localStartDate = startDate?.toLocal();
      final localEndDate = endDate?.toLocal();

      print('🔍 Consultando citas optimizadas (Vista: ${currentView.value}):');
      print('📅 Inicio: ${localStartDate?.toString()}');
      print('📅 Fin: ${localEndDate?.toString()}');

      // Generar clave de caché
      final cacheKey = _generateCacheKey(localStartDate, localEndDate);
      
      // Limpiar caché expirado
      _cleanExpiredCache();
      
      // Verificar si tenemos datos válidos en caché
      if (_isCacheValid(cacheKey)) {
        print('💾 Usando datos del caché para: $cacheKey');
        final cachedAppointments = _appointmentsCache[cacheKey]!;
        appointments.assignAll(cachedAppointments);
        update(['calendar-view']);
        isLoading.value = false;
        return;
      }

      print('🌐 Cargando desde API...');
      final result = await getAppointmentsUseCase(
        startDate: localStartDate,
        endDate: localEndDate,
      );

      print('📊 Citas obtenidas: ${result.length}');

      // PRIMER FILTRO: Por rango de fechas (solucionar problema del backend)
      List<AppointmentEntity> dateFilteredAppointments = [];
      if (localStartDate != null && localEndDate != null) {
        dateFilteredAppointments = result.where((appointment) {
          final appointmentDate = appointment.startTime.toLocal();
          final isInRange = appointmentDate.isAfter(localStartDate.subtract(const Duration(seconds: 1))) &&
                           appointmentDate.isBefore(localEndDate.add(const Duration(seconds: 1)));
          
          if (!isInRange) {
            print('⚠️ Cita fuera de rango descartada: ${appointment.startTime} (${appointment.clientName})');
          }
          return isInRange;
        }).toList();
        
        print('📅 Filtro de fechas: ${dateFilteredAppointments.length} de ${result.length} citas en rango');
      } else {
        dateFilteredAppointments = result;
      }

      // SEGUNDO FILTRO: Por rol del usuario
      List<AppointmentEntity> filteredAppointments = [];

      if (userRole.value == 'Owner') {
        filteredAppointments = dateFilteredAppointments;
        print('👑 Rol Owner: Mostrando todas las citas en rango (${dateFilteredAppointments.length})');
      } else if (userRole.value == 'Employee') {
        filteredAppointments = dateFilteredAppointments.where((appointment) {
          return appointment.professionalId == userId.value;
        }).toList();
        print('👤 Rol Employee: Filtrando citas para el profesional ${userId.value}');
        print('✅ Citas filtradas: ${filteredAppointments.length} de ${dateFilteredAppointments.length}');
      } else {
        filteredAppointments = dateFilteredAppointments;
        print('⚠️ Rol no especificado: Mostrando todas las citas en rango por defecto');
      }

      // Guardar en caché
      _appointmentsCache[cacheKey] = List.from(filteredAppointments);
      _cacheTimestamps[cacheKey] = DateTime.now();
      print('💾 Datos guardados en caché: $cacheKey');

      // Asignar las citas filtradas
      appointments.assignAll(filteredAppointments);

      // Forzar actualización del calendario
      update(['calendar-view']);
    } catch (e) {
      print('❌ Error al cargar citas: $e');
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
    print('🚀 AppointmentsController onInit - optimizado');
    // No inicializar aquí para evitar cargas duplicadas
    // La inicialización se hace en el constructor
  }

  Future<void> createAppointment({
    required String clientId,
    required DateTime startTime,
    String? notes,
  }) async {
    try {
      // Verificar permisos de usuario primero
      final userController = Get.find<UserInfoController>();
      if (!userController.isOwner()) {
        Get.snackbar(
          'Acceso denegado',
          'Solo los usuarios Owner pueden crear citas',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      // Verificar horario del profesional
      if (selectedEmployee.value != null) {
        final isValidTime = _isAppointmentTimeValid(startTime, selectedEmployee.value!);
        if (!isValidTime) {
          Get.snackbar(
            'Horario inválido',
            'La hora seleccionada está fuera del horario de trabajo del profesional',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.orange,
            colorText: Colors.white,
            duration: const Duration(seconds: 4),
          );
          return;
        }
      }

      // Verificar estado de suscripción
      final canContinue = await checkSubscriptionStatus();
      if (!canContinue) {
        // En lugar de mostrar siempre el mismo diálogo, detectar el mensaje para mostrar el adecuado
        final message = subscriptionMessage.value.toLowerCase();
        if (message.contains('límite de citas') ||
            message.contains('plan de prueba') ||
            message.contains('trial')) {
          _showTrialEndedDialog();
        } else {
          _showInactiveSubscriptionDialog();
        }
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

        // Invalidar caché para la fecha afectada
        _invalidateCacheForDate(startTime);

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
        bool isTrialEnded = false;
        bool isSubscriptionInactive = false;

        // Analizar el mensaje de error para determinar el tipo específico
        if (apiError is DioException) {
          final responseData = apiError.response?.data;
          final statusCode = apiError.response?.statusCode;

          if (statusCode == 400 &&
              responseData is Map &&
              responseData['message'] != null) {
            final message = responseData['message'].toString().toLowerCase();

            // Detectar si es fin del plan de prueba o suscripción inactiva
            if (message.contains('límite de citas') ||
                message.contains('plan de prueba') ||
                message.contains('trial')) {
              isTrialEnded = true;
              subscriptionMessage.value = responseData['message'].toString();
            } else if (message.contains('suscripción no está activa') ||
                message.contains('actualiza tu plan')) {
              isSubscriptionInactive = true;
              subscriptionMessage.value = responseData['message'].toString();
            }
          }
        }

        // También verificar en el mensaje de error general si no se detectó antes
        if (!isTrialEnded && !isSubscriptionInactive) {
          final errorMessage = apiError.toString().toLowerCase();

          if (errorMessage.contains('límite de citas') ||
              errorMessage.contains('plan de prueba') ||
              errorMessage.contains('trial')) {
            isTrialEnded = true;
            // Extraer el mensaje para el diálogo, eliminar la parte de AppointmentException
            final message = apiError.toString();
            final cleanMessage = message.contains(':')
                ? message.split(':').last.trim()
                : message;
            subscriptionMessage.value =
                cleanMessage.replaceAll(RegExp(r'\(Code: \d+\)'), '').trim();
          } else if (errorMessage.contains('suscripción no está activa') ||
              errorMessage.contains('actualiza tu plan')) {
            isSubscriptionInactive = true;
            // Extraer el mensaje para el diálogo, eliminar la parte de AppointmentException
            final message = apiError.toString();
            final cleanMessage = message.contains(':')
                ? message.split(':').last.trim()
                : message;
            subscriptionMessage.value =
                cleanMessage.replaceAll(RegExp(r'\(Code: \d+\)'), '').trim();
          }
        }

        // Mostrar el diálogo correspondiente
        if (isTrialEnded) {
          print('ERROR DETECTADO: Fin de plan de prueba - Mostrando diálogo');
          _showTrialEndedDialog();
          return;
        } else if (isSubscriptionInactive) {
          print('ERROR DETECTADO: Suscripción inactiva - Mostrando diálogo');
          _showInactiveSubscriptionDialog();
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

      // Analizar el tipo de error de suscripción
      bool isTrialEnded = false;
      bool isSubscriptionInactive = false;

      if (errorMessage.contains('límite de citas') ||
          errorMessage.contains('plan de prueba') ||
          errorMessage.contains('trial')) {
        isTrialEnded = true;
        // Extraer el mensaje limpio para el diálogo
        final message = e.toString();
        final cleanMessage =
            message.contains(':') ? message.split(':').last.trim() : message;
        subscriptionMessage.value =
            cleanMessage.replaceAll(RegExp(r'\(Code: \d+\)'), '').trim();
      } else if (errorMessage.contains('suscripción no está activa') ||
          errorMessage.contains('actualiza tu plan')) {
        isSubscriptionInactive = true;
        // Extraer el mensaje limpio para el diálogo
        final message = e.toString();
        final cleanMessage =
            message.contains(':') ? message.split(':').last.trim() : message;
        subscriptionMessage.value =
            cleanMessage.replaceAll(RegExp(r'\(Code: \d+\)'), '').trim();
      }

      // Mostrar el diálogo correspondiente
      if (isTrialEnded) {
        print('ERROR DETECTADO: Fin de plan de prueba - Mostrando diálogo');
        _showTrialEndedDialog();
        return;
      } else if (isSubscriptionInactive) {
        print('ERROR DETECTADO: Suscripción inactiva - Mostrando diálogo');
        _showInactiveSubscriptionDialog();
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

      // Invalidar caché para la fecha afectada
      _invalidateCacheForDate(startTime);

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
        '${c.name} ${c.lastname}'.trim() == clientName.trim());

    if (clientMatch != null) {
      print('📍 Cliente encontrado por nombre: ${clientMatch.id}');
      return clientMatch.id ?? '';
    }

    print('⚠️ No se encontró cliente con nombre: "$clientName"');
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
    _sessionWorker?.dispose();
    _employeesController = null;
    selectedServiceIds.clear();
    totalPrice.value = 0;
    _invalidateCache(); // Limpiar caché al cerrar
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

  // Diálogo para cuando se acaba el plan de prueba
  void _showTrialEndedDialog() {
    print('Mostrando diálogo de fin de plan de prueba');

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
                  Icons.star,
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
                'Has alcanzado el límite de citas de tu plan de prueba. Actualiza a un plan premium para continuar gestionando tus citas.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Get.back(); // Cerrar diálogo
                    Get.toNamed(GetRoutes.subscriptionPlans);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
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

// Diálogo para cuando la suscripción no está activa
  void _showInactiveSubscriptionDialog() {
    print('Mostrando diálogo de suscripción inactiva');

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
                  color: Colors.red[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.assignment_late_rounded,
                  color: Colors.red[400],
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Suscripción inactiva',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Tu suscripción no está activa actualmente. Por favor, actualiza tu plan para seguir gestionando tus citas.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Get.back(); // Cerrar diálogo
                    Get.toNamed(GetRoutes.subscriptionPlans);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
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

// Método público para elegir qué diálogo mostrar
  void showSubscriptionDialog() {
    final message = subscriptionMessage.value.toLowerCase();

    if (message.contains('límite de citas') ||
        message.contains('plan de prueba') ||
        message.contains('trial')) {
      _showTrialEndedDialog();
    } else {
      _showInactiveSubscriptionDialog();
    }
  }

  bool _isAppointmentTimeValid(DateTime appointmentTime, dynamic employee) {
    try {
      // Si el empleado no tiene horario definido, permitir cualquier hora
      if (employee.schedule == null || employee.schedule.isEmpty) {
        print('⚠️ Empleado ${employee.name} no tiene horario definido - permitiendo cualquier hora');
        return true;
      }

      // Obtener el día de la semana (lunes = 1, domingo = 7)
      final dayOfWeek = appointmentTime.weekday;
      final dayNames = {
        1: 'monday',
        2: 'tuesday', 
        3: 'wednesday',
        4: 'thursday',
        5: 'friday',
        6: 'saturday',
        7: 'sunday'
      };

      final dayName = dayNames[dayOfWeek];
      if (dayName == null) return false;

      // Verificar si el empleado trabaja ese día
      final daySchedule = employee.schedule[dayName];
      if (daySchedule == null) {
        print('⚠️ Empleado ${employee.name} no trabaja los ${dayName}');
        return false;
      }

      // Obtener horarios de inicio y fin
      final startTimeStr = daySchedule['start']?.toString();
      final endTimeStr = daySchedule['end']?.toString();
      
      if (startTimeStr == null || endTimeStr == null) {
        print('⚠️ Horarios no definidos para ${employee.name} el ${dayName}');
        return false;
      }

      // Parsear horarios (formato: "09:00:00")
      final startTimeParts = startTimeStr.split(':');
      final endTimeParts = endTimeStr.split(':');
      
      if (startTimeParts.length < 2 || endTimeParts.length < 2) {
        print('⚠️ Formato de horario inválido para ${employee.name}');
        return false;
      }

      final startHour = int.parse(startTimeParts[0]);
      final startMinute = int.parse(startTimeParts[1]);
      final endHour = int.parse(endTimeParts[0]);
      final endMinute = int.parse(endTimeParts[1]);

      // Crear horarios del día de la cita
      final appointmentDate = DateTime(appointmentTime.year, appointmentTime.month, appointmentTime.day);
      final workStartTime = appointmentDate.add(Duration(hours: startHour, minutes: startMinute));
      final workEndTime = appointmentDate.add(Duration(hours: endHour, minutes: endMinute));

      // Calcular duración total de los servicios seleccionados
      int totalDurationMinutes = 0;
      for (String serviceId in selectedServiceIds) {
        final service = services.firstWhere((s) => s['id'] == serviceId,
            orElse: () => {'duration': 30});
        totalDurationMinutes += int.parse((service['duration'] ?? 30).toString());
      }

      // Verificar que la cita empiece y termine dentro del horario laboral
      final appointmentEndTime = appointmentTime.add(Duration(minutes: totalDurationMinutes));
      
      final isValid = appointmentTime.isAfter(workStartTime.subtract(const Duration(minutes: 1))) &&
                     appointmentEndTime.isBefore(workEndTime.add(const Duration(minutes: 1)));

      print('🕐 Validación de horario para ${employee.name}:');
      print('   Día: $dayName');
      print('   Horario laboral: ${startTimeStr} - ${endTimeStr}');
      print('   Cita: ${appointmentTime.hour}:${appointmentTime.minute.toString().padLeft(2, '0')} - ${appointmentEndTime.hour}:${appointmentEndTime.minute.toString().padLeft(2, '0')}');
      print('   Duración total: $totalDurationMinutes min');
      print('   ✅ Válido: $isValid');

      return isValid;
    } catch (e) {
      print('❌ Error validando horario: $e');
      return true; // En caso de error, permitir la cita
    }
  }
}
