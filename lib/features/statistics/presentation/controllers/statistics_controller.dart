import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:login_signup/features/auth/presentation/controllers/user_info_controller.dart';
import 'package:login_signup/features/statistics/domain/entities/employee_stats_entity.dart';
import 'package:login_signup/features/statistics/domain/usecases/get_employee_stats_usecase.dart';
import '../../domain/entities/payment_stats_entity.dart';
import '../../domain/entities/payment_comparison_entity.dart';
import '../../domain/entities/payment_method_stats_entity.dart';
import '../../domain/entities/professional_stats_entity.dart';
import '../../domain/entities/service_stats_entity.dart';
import '../../domain/entities/client_stats_entity.dart';
import '../../domain/entities/top_client_entity.dart';
import '../../domain/usecases/get_payment_stats_usecase.dart';
import '../../domain/usecases/get_payment_comparison_usecase.dart';
import '../../domain/usecases/get_payment_stats_by_method_usecase.dart';
import '../../domain/usecases/get_payment_stats_by_professional_usecase.dart';
import '../../domain/usecases/get_payment_stats_by_service_usecase.dart';
import '../../domain/usecases/get_payment_stats_by_client_usecase.dart';
import '../../domain/usecases/get_top_clients_usecase.dart';

class StatisticsController extends GetxController {
  final GetPaymentStatsUseCase getPaymentStatsUseCase;
  final GetPaymentComparisonUseCase getPaymentComparisonUseCase;
  final GetPaymentStatsByMethodUseCase getPaymentStatsByMethodUseCase;
  final GetPaymentStatsByProfessionalUseCase
      getPaymentStatsByProfessionalUseCase;
  final GetPaymentStatsByServiceUseCase getPaymentStatsByServiceUseCase;
  final GetPaymentStatsByClientUseCase getPaymentStatsByClientUseCase;
  final GetTopClientsUseCase getTopClientsUseCase;

  final GetEmployeeStatsUseCase getEmployeeStatsUseCase;

  final UserInfoController userInfoController = Get.find<UserInfoController>();

  // Para formatear valores monetarios
  final currencyFormat = NumberFormat.currency(
    locale: 'es_CO',
    symbol: '\$',
    decimalDigits: 0,
    customPattern:
        '\$ #,###', // Define un patrón personalizado con el $ a la izquierda
  );

  // Para formatear porcentajes
  final percentFormat = NumberFormat.percentPattern('es_CO');

  // Para formatear fechas
  final dateFormat = DateFormat('dd/MM/yyyy');

  // Estado observable de la fecha seleccionada
  final Rx<DateTimeRange> selectedDateRange = Rx<DateTimeRange>(
    DateTimeRange(
      start: DateTime.now().subtract(const Duration(days: 30)),
      end: DateTime.now(),
    ),
  );

  // Estados observables para los resultados de las consultas
  final Rx<PaymentStatsEntity?> paymentStats = Rx<PaymentStatsEntity?>(null);
  final Rx<PaymentComparisonEntity?> paymentComparison =
      Rx<PaymentComparisonEntity?>(null);
  final RxList<PaymentMethodStatsEntity> paymentMethodStats =
      <PaymentMethodStatsEntity>[].obs;
  final RxList<ProfessionalStatsEntity> professionalStats =
      <ProfessionalStatsEntity>[].obs;
  final RxList<ServiceStatsEntity> serviceStats = <ServiceStatsEntity>[].obs;
  final RxList<ClientStatsEntity> clientStats = <ClientStatsEntity>[].obs;
  final RxList<TopClientEntity> topClients = <TopClientEntity>[].obs;

  final Rx<EmployeeStatsEntity?> employeeStats = Rx<EmployeeStatsEntity?>(null);

  // Estados para la carga y errores
  final RxBool isLoadingOverview = false.obs;
  final RxBool isLoadingPaymentMethods = false.obs;
  final RxBool isLoadingProfessionals = false.obs;
  final RxBool isLoadingServices = false.obs;
  final RxBool isLoadingClients = false.obs;
  final RxBool isLoadingTopClients = false.obs;

  final RxString errorOverview = ''.obs;
  final RxString errorPaymentMethods = ''.obs;
  final RxString errorProfessionals = ''.obs;
  final RxString errorServices = ''.obs;
  final RxString errorClients = ''.obs;
  final RxString errorTopClients = ''.obs;

  final RxBool isPaymentMethodsExpanded = false.obs;
  final RxBool isProfessionalsExpanded = false.obs;
  final RxBool isServicesExpanded = false.obs;
  final RxBool isTopClientsExpanded = false.obs;

  final RxBool isLoadingEmployeeStats = false.obs;
  final RxString errorEmployeeStats = ''.obs;

  StatisticsController({
    required this.getPaymentStatsUseCase,
    required this.getPaymentComparisonUseCase,
    required this.getPaymentStatsByMethodUseCase,
    required this.getPaymentStatsByProfessionalUseCase,
    required this.getPaymentStatsByServiceUseCase,
    required this.getPaymentStatsByClientUseCase,
    required this.getTopClientsUseCase,
    required this.getEmployeeStatsUseCase,
  });

  void _initializeDefaultDateRange() {
    // Obtener la fecha actual
    final DateTime now = DateTime.now();

    // Crear el inicio del día actual (00:00:00)
    final DateTime startOfToday = DateTime(now.year, now.month, now.day);

    // Crear el final del día actual (23:59:59)
    final DateTime endOfToday =
        DateTime(now.year, now.month, now.day, 23, 59, 59);

    // Establecer el rango de fecha predeterminado como el día actual
    selectedDateRange.value = DateTimeRange(
      start: startOfToday,
      end: endOfToday,
    );

    // Inicialmente cargar datos para hoy
    loadOverviewData();
  }

  // Método para cargar datos basados en el rol
  Future<void> loadStatsBasedOnRole() async {
    // Verificar si es solo Employee
    if (userInfoController.isOnlyEmployee()) {
      print("Usuario es solo Employee, cargando estadísticas de empleado");
      await loadEmployeeStats();
    } else {
      print(
          "Usuario es Owner o tiene otros roles, cargando estadísticas completas");
      await loadOverviewData();
      // Cargar otras estadísticas si es necesario
    }
  }

  @override
  void onInit() {
    super.onInit();
    // Configurar el rango de fechas por defecto (día actual)
    final now = DateTime.now();
    selectedDateRange.value = DateTimeRange(
      start: DateTime(now.year, now.month, now.day),
      end: DateTime(now.year, now.month, now.day, 23, 59, 59),
    );
    loadOverviewData();
    loadStatsBasedOnRole();
  }

  // Método para cambiar el rango de fechas
  void setDateRange(DateTimeRange dateRange) {
    selectedDateRange.value = dateRange;
    refresh();
    //loadOverviewData();
    loadStatsBasedOnRole();
  }

  // Método para cargar los datos de resumen (stats y comparación)
  Future<void> loadOverviewData() async {
    isLoadingOverview.value = true;
    errorOverview.value = '';

    try {
      final stats = await getPaymentStatsUseCase(
        selectedDateRange.value.start,
        selectedDateRange.value.end,
      );
      paymentStats.value = stats;

      final comparison = await getPaymentComparisonUseCase(
        selectedDateRange.value.start,
        selectedDateRange.value.end,
      );
      paymentComparison.value = comparison;
    } catch (e) {
      errorOverview.value = e.toString();
      debugPrint('Error cargando datos generales: $e');
    } finally {
      isLoadingOverview.value = false;
    }
  }

  // Método para cargar estadísticas por método de pago
  Future<void> loadPaymentMethodStats() async {
    isLoadingPaymentMethods.value = true;
    errorPaymentMethods.value = '';

    try {
      final stats = await getPaymentStatsByMethodUseCase(
        selectedDateRange.value.start,
        selectedDateRange.value.end,
      );
      paymentMethodStats.assignAll(stats);
    } catch (e) {
      errorPaymentMethods.value = e.toString();
      debugPrint('Error cargando estadísticas por método de pago: $e');
    } finally {
      isLoadingPaymentMethods.value = false;
    }
  }

  // Método para cargar estadísticas por profesional
  Future<void> loadProfessionalStats() async {
    isLoadingProfessionals.value = true;
    errorProfessionals.value = '';

    try {
      final stats = await getPaymentStatsByProfessionalUseCase(
        selectedDateRange.value.start,
        selectedDateRange.value.end,
      );
      professionalStats.assignAll(stats);
    } catch (e) {
      errorProfessionals.value = e.toString();
      debugPrint('Error cargando estadísticas por profesional: $e');
    } finally {
      isLoadingProfessionals.value = false;
    }
  }

  Future<void> loadEmployeeStats() async {
    isLoadingEmployeeStats.value = true;
    errorEmployeeStats.value = '';

    try {
      final stats = await getEmployeeStatsUseCase(
        selectedDateRange.value.start,
        selectedDateRange.value.end,
      );
      employeeStats.value = stats;
    } catch (e) {
      errorEmployeeStats.value = e.toString();
      debugPrint('Error cargando estadísticas de empleado: $e');
    } finally {
      isLoadingEmployeeStats.value = false;
    }
  }

  // Método para cargar estadísticas por servicio
  Future<void> loadServiceStats() async {
    isLoadingServices.value = true;
    errorServices.value = '';

    try {
      final stats = await getPaymentStatsByServiceUseCase(
        selectedDateRange.value.start,
        selectedDateRange.value.end,
      );
      serviceStats.assignAll(stats);
    } catch (e) {
      errorServices.value = e.toString();
      debugPrint('Error cargando estadísticas por servicio: $e');
    } finally {
      isLoadingServices.value = false;
    }
  }

  // Método para cargar estadísticas por cliente
  Future<void> loadClientStats({int limit = 10}) async {
    isLoadingClients.value = true;
    errorClients.value = '';

    try {
      final stats = await getPaymentStatsByClientUseCase(
        selectedDateRange.value.start,
        selectedDateRange.value.end,
        limit: limit,
      );
      clientStats.assignAll(stats);
    } catch (e) {
      errorClients.value = e.toString();
      debugPrint('Error cargando estadísticas por cliente: $e');
    } finally {
      isLoadingClients.value = false;
    }
  }

  // Método para cargar los mejores clientes
  Future<void> loadTopClients({int limit = 5}) async {
    isLoadingTopClients.value = true;
    errorTopClients.value = '';

    try {
      final stats = await getTopClientsUseCase(
        selectedDateRange.value.start,
        selectedDateRange.value.end,
        limit: limit,
      );
      topClients.assignAll(stats);
    } catch (e) {
      errorTopClients.value = e.toString();
      debugPrint('Error cargando mejores clientes: $e');
    } finally {
      isLoadingTopClients.value = false;
    }
  }

  // Método para cargar todos los datos
  Future<void> loadAllStats() async {
    await loadOverviewData();
    await loadEmployeeStats();
    await loadPaymentMethodStats();
    await loadProfessionalStats();
    await loadServiceStats();
    await loadTopClients();
  }

  // Métodos de utilidad para formatear datos
  String formatCurrency(dynamic value) {
    // Convertir el valor a double independientemente de si es int, double o null
    final doubleValue =
        value is int ? value.toDouble() : (value is double ? value : 0.0);

    // Crear un formato sin el símbolo '$'
    final formatWithoutSymbol = NumberFormat('#,###', 'es_CO');

    // Retornar el formato con el símbolo $ a la izquierda usando interpolación
    return '\$ ${formatWithoutSymbol.format(doubleValue)}';
  }

  String formatPercent(double value) {
    // Convertir a decimal para el formateador (ej. 15% -> 0.15)
    final decimalValue = value / 100;
    return percentFormat.format(decimalValue);
  }

  String formatDate(DateTime date) {
    return dateFormat.format(date);
  }

  // Obtiene el color según el porcentaje de cambio (positivo verde, negativo rojo)
  Color getPercentageColor(double percentage) {
    if (percentage > 0) {
      return Colors.green;
    } else if (percentage < 0) {
      return Colors.red;
    }
    return Colors.grey;
  }

  // Obtiene el ícono según el porcentaje de cambio
  IconData getPercentageIcon(double percentage) {
    if (percentage > 0) {
      return Icons.arrow_upward;
    } else if (percentage < 0) {
      return Icons.arrow_downward;
    }
    return Icons.remove;
  }

  // Método para refrescar todos los datos
  void refreshAllStats() {
    loadAllStats();
  }

  // Métodos para alternar la visibilidad
  void togglePaymentMethods() {
    isPaymentMethodsExpanded.value = !isPaymentMethodsExpanded.value;
    if (isPaymentMethodsExpanded.value && paymentMethodStats.isEmpty) {
      loadPaymentMethodStats();
    }
  }

  void toggleProfessionals() {
    isProfessionalsExpanded.value = !isProfessionalsExpanded.value;
    if (isProfessionalsExpanded.value && professionalStats.isEmpty) {
      loadProfessionalStats();
    }
  }

  void toggleServices() {
    isServicesExpanded.value = !isServicesExpanded.value;
    if (isServicesExpanded.value && serviceStats.isEmpty) {
      loadServiceStats();
    }
  }

  void toggleTopClients() {
    isTopClientsExpanded.value = !isTopClientsExpanded.value;
    if (isTopClientsExpanded.value && topClients.isEmpty) {
      loadTopClients();
    }
  }
}
