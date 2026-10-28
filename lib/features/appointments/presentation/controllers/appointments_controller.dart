import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/session/session_repository.dart';
import 'package:login_signup/shared/controller/session_controller.dart';

import 'package:login_signup/features/employees/domain/usecases/get_employee_by_id_usecase.dart';
import 'package:login_signup/features/employees/domain/usecases/get_employees_usecase.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:login_signup/features/auth/presentation/controllers/user_info_controller.dart';

import 'package:login_signup/features/appointments/domain/entities/appointment_changes.dart';
import 'package:login_signup/features/appointments/domain/entities/appointment_entity.dart';
import 'package:login_signup/features/appointments/domain/entities/appointment_queries.dart';
import 'package:login_signup/features/appointments/domain/entities/new_appointment.dart';
import 'package:login_signup/features/appointments/domain/failures/appointment_failures.dart';
import 'package:login_signup/features/appointments/domain/usecases/create_appointment_usecase.dart';
import 'package:login_signup/features/appointments/domain/usecases/get_appointments_usecase.dart';
import 'package:login_signup/features/appointments/domain/usecases/update_appointment_usecase.dart';
import 'package:login_signup/features/appointments/presentation/widgets/appointment_calendar_data_source.dart';

import 'package:login_signup/features/clients/domain/entities/clients_query.dart';
import 'package:login_signup/features/clients/domain/usecases/get_clients_page_usecase.dart';
import 'package:login_signup/features/clients/domain/entities/client_entity.dart';

import 'package:login_signup/features/employees/domain/entities/employee_entity.dart';

import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/features/services/domain/entities/service_entity.dart';
import 'package:login_signup/features/services/domain/usecases/get_services_usecase.dart';

// Nuevas importaciones para la funcionalidad de suscripción
import 'package:login_signup/features/subscriptions/domain/entities/subscription_limits.dart';
import 'package:login_signup/features/subscriptions/domain/usecases/check_subscription_limits_usecase.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/shared/widgets/app_dialogs.dart';
import 'package:login_signup/shared/widgets/app_snackbar.dart';

class AppointmentsController extends GetxController {
  final GetAppointmentsUseCase getAppointmentsUseCase;
  final CreateAppointmentUseCase createAppointmentUseCase;
  final UpdateAppointmentUseCase updateAppointmentUseCase;
  final GetServicesUseCase getServicesUseCase;
  final GetClientsPageUseCase getClientsPageUseCase;

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
  late CheckSubscriptionLimitsUseCase? checkSubscriptionStatusUseCase;
  final RxBool canCreateAppointment = true.obs;
  final RxString subscriptionMessage = ''.obs;

  /// Motivo del último bloqueo de `check-limits` (por `code`, no por texto).
  SubscriptionBlock? _subscriptionBlock;

  /// Profesionales que se pueden elegir en una cita. Appointments los pide
  /// con los use cases de employees; no usa el controller de esa feature.
  final GetEmployeesUseCase getProfessionalsUseCase;
  final GetEmployeeByIdUseCase getProfessionalByIdUseCase;
  final RxList<EmployeeEntity> professionals = <EmployeeEntity>[].obs;
  final RxBool isLoadingProfessionals = false.obs;

  /// Profesionales a los que se puede agendar (activos y sin baja).
  List<EmployeeEntity> get schedulableProfessionals =>
      professionals.where((e) => e.canBeScheduled).toList();

  /// Carga los profesionales del negocio (solo el Owner puede listarlos).
  Future<void> loadProfessionals() async {
    if (isLoadingProfessionals.value) return;
    isLoadingProfessionals.value = true;
    final result = await getProfessionalsUseCase(NoParams());
    isLoadingProfessionals.value = false;
    result.fold((_) {}, professionals.assignAll);
  }

  /// El profesional [id], de la lista cargada o del backend; `null` si no se
  /// puede leer (p. ej. un Employee, que no lista profesionales).
  Future<EmployeeEntity?> findProfessional(String id) async {
    final local = professionals.firstWhereOrNull((e) => e.id == id);
    if (local != null) return local;
    final result = await getProfessionalByIdUseCase(id);
    return result.fold((_) => null, (employee) => employee);
  }

  /// Nombre para mostrar del profesional [id]. Si es el propio usuario, su
  /// nombre de la sesión.
  Future<String> professionalName(String id) async {
    final employee = await findProfessional(id);
    if (employee != null) return employee.fullName;
    final session = Get.isRegistered<SessionController>()
        ? Get.find<SessionController>().session.value
        : null;
    if (session != null && session.userId == id) {
      final name = session.name?.trim() ?? '';
      if (name.isNotEmpty) return name;
    }
    return 'Profesional';
  }

  AppointmentsController(
      {required this.getAppointmentsUseCase,
      required this.createAppointmentUseCase,
      required this.updateAppointmentUseCase,
      required this.getServicesUseCase,
      required this.getClientsPageUseCase,
      required this.getProfessionalsUseCase,
      required this.getProfessionalByIdUseCase,
      this.checkSubscriptionStatusUseCase}) {
    _getUserInfo();
    _initializeCalendar();
    _loadInitialData();
    
    // ✅ CONFIGURAR BÚSQUEDA REACTIVA CON DEBOUNCE OPTIMIZADO PARA EL SERVIDOR
    debounce(clientSearchQuery, (_) => _searchClientsFromServer(), time: const Duration(milliseconds: 800));

    // Intentar obtener el servicio de suscripción si no fue inyectado
    if (checkSubscriptionStatusUseCase == null) {
      try {
        checkSubscriptionStatusUseCase =
            Get.find<CheckSubscriptionLimitsUseCase>();
      } catch (e) {
        print('No se encontró CheckSubscriptionLimitsUseCase: $e');
      }
    }
  }

  Future<bool> checkSubscriptionStatus() async {
    try {
      print('Verificando estado de suscripción...');

      if (checkSubscriptionStatusUseCase == null) {
        print(
            'CheckSubscriptionLimitsUseCase es null, intentando encontrarlo...');
        try {
          checkSubscriptionStatusUseCase =
              Get.find<CheckSubscriptionLimitsUseCase>();
          print('CheckSubscriptionLimitsUseCase encontrado con éxito');
        } catch (e) {
          print('No se pudo encontrar CheckSubscriptionLimitsUseCase: $e');
          return true; // Por defecto, permitir si no se puede verificar
        }
      }

      if (checkSubscriptionStatusUseCase == null) {
        print('CheckSubscriptionLimitsUseCase sigue siendo null');
        return true;
      }

      final result = await checkSubscriptionStatusUseCase!.call(NoParams());
      return result.fold(
        // Si no se puede comprobar, se deja seguir: el backend vuelve a
        // validarlo al crear la cita.
        (failure) => true,
        (limits) {
          canCreateAppointment.value = limits.canCreateAppointment;
          subscriptionMessage.value = limits.message;
          _subscriptionBlock = limits.block;
          return limits.canCreateAppointment;
        },
      );
    } catch (e) {
      print('Error verificando estado de suscripción: $e');
      return true;
    }
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
    final result = await getServicesUseCase(NoParams());
    result.fold(
      (failure) => error.value = failure.message,
      (loaded) => services.assignAll(loaded.map(_serviceAsMap)),
    );
  }

  /// Puente hasta la 4.09: esta feature aún lee los servicios como mapas
  /// (solo estas claves). Se quita al pasar `services` a `ServiceEntity`.
  static Map<String, dynamic> _serviceAsMap(ServiceEntity s) => {
        'id': s.id,
        'name': s.name,
        'description': s.description,
        'price': s.price,
        'duration': s.duration,
        'color': s.color,
      };

  // ✅ NUEVO MÉTODO: CARGAR CLIENTES CON PAGINACIÓN REAL DEL SERVIDOR
  Future<void> loadClients() async {
    try {
      print('🔄 AppointmentsController: Cargando clientes con paginación del servidor...');
      isClientsLoading.value = true;
      clientsCurrentPage.value = 1;

      final result = (await getClientsPageUseCase(ClientsQuery(
        page: clientsCurrentPage.value,
        limit: clientsPageSize.value,
        search: clientSearchQuery.value,
      )))
          .fold((failure) => throw Exception(failure.message), (page) => page);

      // ✅ ACTUALIZAR VARIABLES DE PAGINACIÓN
      hasMoreClients.value = result.hasNextPage;
      
      // ✅ REEMPLAZAR LOS CLIENTES (PRIMERA PÁGINA)
      clients.assignAll(result.items);
      
      print('✅ Clientes cargados: ${result.items.length}');
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

      final result = (await getClientsPageUseCase(ClientsQuery(
        page: clientsCurrentPage.value,
        limit: clientsPageSize.value,
        search: clientSearchQuery.value,
      )))
          .fold((failure) => throw Exception(failure.message), (page) => page);

      // ✅ ACTUALIZAR VARIABLES DE PAGINACIÓN
      hasMoreClients.value = result.hasNextPage;
      
      // ✅ AÑADIR MÁS CLIENTES A LA LISTA EXISTENTE
      clients.addAll(result.items);
      
      print('✅ Más clientes cargados: ${result.items.length}');
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
    return '${start}_${end}_${role}_$user';
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
      // El repositorio ya filtra por el rango (fin excluido).
      final loaded = (await getAppointmentsUseCase(AppointmentsRange(
        start: localStartDate!,
        end: localEndDate!.add(const Duration(seconds: 1)),
      )))
          .fold((failure) {
        error.value = failure.message;
        return null;
      }, (appointments) => appointments);
      if (loaded == null) return;
      final result = loaded;

      print('📊 Citas obtenidas: ${result.length}');

      // PRIMER FILTRO: Por rango de fechas (solucionar problema del backend)
      final List<AppointmentEntity> dateFilteredAppointments = result;

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

  String _formatErrorMessage(Object error) =>
      error is Failure ? error.message : error.toString();

  /// Avisa de un failure al crear o editar: diálogo de suscripción o de
  /// horario por tipo (es decir, por `code`), y si no, el texto del failure.
  void _showSaveFailure(Failure failure, String action) {
    error.value = failure.message;
    if (failure is TrialLimitReachedFailure) {
      subscriptionMessage.value = failure.message;
      _showSubscriptionBlocked(SubscriptionBlockReason.trialEnded);
    } else if (failure is SubscriptionInactiveFailure) {
      subscriptionMessage.value = failure.message;
      _showSubscriptionBlocked(SubscriptionBlockReason.inactive);
    } else if (failure is SlotUnavailableFailure) {
      _showScheduleUnavailable();
    } else {
      AppSnackbar.error('No se pudo $action la cita: ${failure.message}');
    }
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
        showSubscriptionDialog();
        return;
      }

      if (selectedServiceIds.isEmpty) {
        throw Exception('Debe seleccionar al menos un servicio');
      }

      if (selectedEmployee.value == null) {
        throw Exception('Debe seleccionar un profesional');
      }

      isLoading.value = true;
      error.value = null;

      final result = await createAppointmentUseCase(NewAppointment(
        clientId: clientId,
        professionalId: selectedEmployee.value!.id,
        serviceIds: selectedServiceIds.toList(),
        start: startTime,
        notes: notes,
      ));
      await result.fold(
        (failure) async => _showSaveFailure(failure, 'crear'),
        (_) async {
          selectedServiceIds.clear();
          totalPrice.value = 0;

          // Invalidar caché para la fecha afectada y recargar el día
          _invalidateCacheForDate(startTime);
          await _reloadAppointmentsForDay(startTime);

          AppSnackbar.success('Cita creada correctamente');
          update(['calendar-view']);
        },
      );
    } catch (e) {
      // Validaciones locales de arriba (servicios o profesional sin elegir).
      error.value = e.toString();
      AppSnackbar.error('No se pudo crear la cita: ${_formatErrorMessage(e)}');
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


  Future<void> selectEmployee(EmployeeEntity employee) async {
    selectedEmployee.value = employee;
  }


  /// Edita la cita enviando solo lo que cambió (no consulta el cupo del
  /// plan: editar no consume citas). `true` si se guardó (o no había
  /// cambios); `false` si falló, después de avisar al usuario.
  Future<bool> updateAppointment({
    required String appointmentId,
    required String professionalId,
    required List<String> serviceIds,
    required DateTime startTime,
    String? notes,
    String? clientId,
  }) async {
    final original =
        appointments.firstWhereOrNull((a) => a.id == appointmentId);
    if (original == null) {
      AppSnackbar.error('No se encontró la cita en la agenda cargada');
      return false;
    }
    isLoading.value = true;
    error.value = null;
    final result = await updateAppointmentUseCase(UpdateAppointmentParams(
      original: original,
      changes: AppointmentChanges.between(
        original,
        clientId: clientId,
        professionalId: professionalId,
        serviceIds: serviceIds,
        start: startTime,
        notes: notes,
      ),
    ));
    isLoading.value = false;
    return result.fold<Future<bool>>(
      (failure) async {
        _showSaveFailure(failure, 'actualizar');
        return false;
      },
      (_) async {
        selectedServiceIds.clear();
        totalPrice.value = 0;
        _invalidateCacheForDate(original.startTime);
        _invalidateCacheForDate(startTime);
        await _reloadAppointmentsForDay(startTime);
        AppSnackbar.success('Cita actualizada correctamente');
        update(['calendar-view']);
        return true;
      },
    );
  }

  CalendarDataSource getCalendarDataSource() =>
      AppointmentCalendarDataSource(appointments);

  void onDaySelected(DateTime date) {
    selectedDate.value = date;
    changeView(CalendarView.day, targetDate: date);
  }

  @override
  void onClose() {
    _sessionWorker?.dispose();
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



  // Diálogos comunes (shared/widgets/app_dialogs.dart). La clasificación por
  // texto del error se sustituye por `code` en la 4.09.
  void _showSubscriptionBlocked(SubscriptionBlockReason reason) {
    AppDialogs.subscriptionRequired(reason: reason);
  }

  void _showScheduleUnavailable() {
    final employee = selectedEmployee.value;
    final who = employee == null
        ? 'El profesional'
        : 'El profesional ${employee.name} ${employee.lastname}'.trim();
    AppDialogs.info(
      title: 'Horario no disponible',
      message: '$who no está disponible en este horario.',
      detail: 'Selecciona otra hora o elige otro profesional.',
      tone: AppTone.warning,
      icon: Icons.schedule,
      barrierDismissible: false,
    );
  }

// Método público para elegir qué diálogo mostrar
  void showSubscriptionDialog() {
    _showSubscriptionBlocked(
        _subscriptionBlock == SubscriptionBlock.trialLimitReached
            ? SubscriptionBlockReason.trialEnded
            : SubscriptionBlockReason.inactive);
  }

  bool _isAppointmentTimeValid(
      DateTime appointmentTime, EmployeeEntity employee) {
    try {
      // Si el empleado no tiene horario definido, permitir cualquier hora
      if (employee.schedule.isEmpty) {
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
        print('⚠️ Empleado ${employee.name} no trabaja los $dayName');
        return false;
      }

      // Obtener horarios de inicio y fin
      final startTimeStr = daySchedule.start;
      final endTimeStr = daySchedule.end;

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
      print('   Horario laboral: $startTimeStr - $endTimeStr');
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
