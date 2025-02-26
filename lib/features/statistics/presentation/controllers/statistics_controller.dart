import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
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

  // Para formatear valores monetarios
  final currencyFormat = NumberFormat.currency(
    locale: 'es_CO',
    symbol: '\$',
    decimalDigits: 0,
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

  StatisticsController({
    required this.getPaymentStatsUseCase,
    required this.getPaymentComparisonUseCase,
    required this.getPaymentStatsByMethodUseCase,
    required this.getPaymentStatsByProfessionalUseCase,
    required this.getPaymentStatsByServiceUseCase,
    required this.getPaymentStatsByClientUseCase,
    required this.getTopClientsUseCase,
  });

  @override
  void onInit() {
    super.onInit();
    loadOverviewData();
  }

  // Método para cambiar el rango de fechas
  void setDateRange(DateTimeRange dateRange) {
    selectedDateRange.value = dateRange;
    refresh();
    loadOverviewData();
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
    await loadPaymentMethodStats();
    await loadProfessionalStats();
    await loadServiceStats();
    await loadTopClients();
  }

  // Métodos de utilidad para formatear datos
  String formatCurrency(double value) {
    return currencyFormat.format(value);
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
}
