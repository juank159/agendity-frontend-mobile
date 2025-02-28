// lib/features/statistics/presentation/screens/statistics_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/features/statistics/presentation/widgets/expandable_section.dart';
import '../controllers/statistics_controller.dart';
import '../widgets/date_range_selector.dart';
import '../widgets/overview_stats_card.dart';
import '../widgets/stats_section_header.dart';
import '../widgets/payment_comparison_card.dart';
import '../widgets/top_clients_widget.dart';
import '../widgets/payment_methods_chart.dart';
import '../widgets/professionals_performance_widget.dart';
import '../widgets/services_performance_widget.dart';

class StatisticsDashboardScreen extends StatelessWidget {
  const StatisticsDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<StatisticsController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard de Estadísticas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: controller.refreshAllStats,
            tooltip: 'Actualizar datos',
          ),
        ],
      ),
      body: Obx(() {
        // Mostrar indicador de carga si estamos cargando datos iniciales
        if (controller.isLoadingOverview.value &&
            controller.paymentStats.value == null) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        // Mostrar error si hay uno
        if (controller.errorOverview.value.isNotEmpty &&
            controller.paymentStats.value == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Error al cargar datos',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(controller.errorOverview.value),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: controller.loadOverviewData,
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }

        // Mostrar el dashboard
        return RefreshIndicator(
          onRefresh: () => controller.loadAllStats(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Selector de rango de fechas
                DateRangeSelector(
                  selectedDateRange: controller.selectedDateRange.value,
                  onDateRangeSelected: controller.setDateRange,
                ),

                const SizedBox(height: 16),

                // Tarjeta de resumen
                if (controller.paymentStats.value != null)
                  OverviewStatsCard(stats: controller.paymentStats.value!),

                const SizedBox(height: 24),

                // Comparación con período anterior
                const StatsSectionHeader(
                  title: 'Comparación con período anterior',
                  icon: Icons.compare_arrows,
                ),
                if (controller.paymentComparison.value != null)
                  PaymentComparisonCard(
                      comparison: controller.paymentComparison.value!),

                const SizedBox(height: 24),

                // Métodos de pago
                ExpandableSection(
                  title: 'Métodos de pago',
                  icon: Icons.payment,
                  isExpanded: controller.isPaymentMethodsExpanded,
                  onToggle: controller.togglePaymentMethods,
                  child: PaymentMethodsChart(),
                ),

                const SizedBox(height: 8),

                // Rendimiento por profesional
                ExpandableSection(
                  title: 'Rendimiento por profesional',
                  icon: Icons.person,
                  isExpanded: controller.isProfessionalsExpanded,
                  onToggle: controller.toggleProfessionals,
                  child: ProfessionalsPerformanceWidget(),
                ),

                const SizedBox(height: 8),

                // Rendimiento por servicio
                ExpandableSection(
                  title: 'Rendimiento por servicio',
                  icon: Icons.spa,
                  isExpanded: controller.isServicesExpanded,
                  onToggle: controller.toggleServices,
                  child: ServicesPerformanceWidget(),
                ),

                const SizedBox(height: 8),

                // Top clientes
                ExpandableSection(
                  title: 'Mejores clientes',
                  icon: Icons.people,
                  isExpanded: controller.isTopClientsExpanded,
                  onToggle: controller.toggleTopClients,
                  child: TopClientsWidget(),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      }),
    );
  }
}
