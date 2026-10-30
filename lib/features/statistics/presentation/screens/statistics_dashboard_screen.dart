import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/routes/routes.dart';
import 'package:login_signup/core/widgets/error_state.dart';
import 'package:login_signup/core/widgets/list_state_view.dart';
import '../../domain/entities/payment_method_stats_entity.dart';
import '../../domain/entities/professional_stats_entity.dart';
import '../../domain/entities/service_stats_entity.dart';
import '../../domain/entities/top_client_entity.dart';
import '../controllers/statistics_controller.dart';
import '../widgets/date_range_selector.dart';
import '../widgets/expandable_section.dart';
import '../widgets/overview_stats_card.dart';
import '../widgets/payment_comparison_card.dart';
import '../widgets/payment_methods_chart.dart';
import '../widgets/professionals_performance_widget.dart';
import '../widgets/services_performance_widget.dart';
import '../widgets/stats_card.dart';
import '../widgets/stats_section_view.dart';
import '../widgets/top_clients_widget.dart';

/// Estadísticas del negocio (solo Owner). Ingresos netos por días del
/// negocio; los bloques plegables se cargan al abrirlos.
class StatisticsDashboardScreen extends GetView<StatisticsController> {
  const StatisticsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (!controller.canView) {
      return Scaffold(
        appBar: AppBar(title: const Text('Estadísticas')),
        body: const ErrorState(
          title: 'Sin acceso',
          icon: Icons.lock_outline,
          message: StatisticsController.ownerOnlyMessage,
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estadísticas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.percent),
            tooltip: 'Comisiones',
            onPressed: () => Get.toNamed(GetRoutes.commissions),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
            onPressed: controller.refreshAll,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: controller.refreshAll,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            Obx(() => DateRangeSelector(
                  selected: controller.range.value,
                  today: controller.today,
                  onChanged: controller.setRange,
                )),
            const SizedBox(height: 16),
            StatsSectionView(
              section: controller.overview,
              onRetry: controller.loadOverview,
              loadingMessage: 'Cargando estadísticas…',
              isEmpty: (stats) => stats.isEmpty,
              emptySubMessage: 'Prueba con un período más amplio.',
              builder: (context, stats) => OverviewStatsCard(stats: stats),
            ),
            const SizedBox(height: 16),
            StatsCard(
              title: 'Comparación con el período anterior',
              child: StatsSectionView(
                section: controller.comparison,
                onRetry: controller.loadOverview,
                builder: (context, comparison) =>
                    PaymentComparisonCard(comparison: comparison),
              ),
            ),
            const SizedBox(height: 8),
            _Section(
              section: StatsDashboardSection.paymentMethods,
              title: 'Métodos de pago',
              icon: Icons.payment,
              child: Obx(() => ListStateView<PaymentMethodStatsEntity>(
                    isLoading: controller.paymentMethods.isLoading.value,
                    error: controller.paymentMethods.error.value,
                    items: controller.paymentMethods.data.value ?? const [],
                    onRetry: _retry(StatsDashboardSection.paymentMethods),
                    emptyIcon: Icons.payment,
                    emptyMessage: 'Sin pagos en este período',
                    builder: (context, stats) =>
                        PaymentMethodsChart(stats: stats),
                  )),
            ),
            _Section(
              section: StatsDashboardSection.professionals,
              title: 'Ingresos por profesional',
              icon: Icons.person_outline,
              child: Obx(() => ListStateView<ProfessionalStatsEntity>(
                    isLoading: controller.professionals.isLoading.value,
                    error: controller.professionals.error.value,
                    items: controller.professionals.data.value ?? const [],
                    onRetry: _retry(StatsDashboardSection.professionals),
                    emptyIcon: Icons.person_outline,
                    emptyMessage: 'Sin pagos en este período',
                    builder: (context, stats) =>
                        ProfessionalsPerformanceWidget(stats: stats),
                  )),
            ),
            _Section(
              section: StatsDashboardSection.services,
              title: 'Servicios',
              icon: Icons.spa_outlined,
              child: Obx(() => ListStateView<ServiceStatsEntity>(
                    isLoading: controller.services.isLoading.value,
                    error: controller.services.error.value,
                    items: controller.services.data.value ?? const [],
                    onRetry: _retry(StatsDashboardSection.services),
                    emptyIcon: Icons.spa_outlined,
                    emptyMessage: 'Sin servicios pagados en este período',
                    builder: (context, stats) =>
                        ServicesPerformanceWidget(stats: stats),
                  )),
            ),
            _Section(
              section: StatsDashboardSection.topClients,
              title: 'Mejores clientes',
              icon: Icons.people_outline,
              child: Obx(() => ListStateView<TopClientEntity>(
                    isLoading: controller.topClients.isLoading.value,
                    error: controller.topClients.error.value,
                    items: controller.topClients.data.value ?? const [],
                    onRetry: _retry(StatsDashboardSection.topClients),
                    emptyIcon: Icons.people_outline,
                    emptyMessage: 'Sin clientes con pagos en este período',
                    builder: (context, clients) => TopClientsWidget(
                      clients: clients,
                      onShowMore: controller.canShowMoreTopClients
                          ? controller.showMoreTopClients
                          : null,
                    ),
                  )),
            ),
          ],
        ),
      ),
    );
  }

  VoidCallback _retry(StatsDashboardSection section) =>
      () => controller.loadSection(section);
}

class _Section extends GetView<StatisticsController> {
  final StatsDashboardSection section;
  final String title;
  final IconData icon;
  final Widget child;

  const _Section({
    required this.section,
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() => ExpandableSection(
          title: title,
          icon: icon,
          isExpanded: controller.isExpanded(section),
          onToggle: () => controller.toggle(section),
          child: child,
        ));
  }
}
