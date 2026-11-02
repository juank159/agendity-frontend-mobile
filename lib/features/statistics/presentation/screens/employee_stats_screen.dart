import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_signup/core/routes/routes.dart';
import '../controllers/employee_stats_controller.dart';
import '../widgets/date_range_selector.dart';
import '../widgets/employee_stats_widget.dart';
import '../widgets/stats_section_view.dart';

/// "Mis estadísticas": las del profesional que inició sesión.
class EmployeeStatsScreen extends GetView<EmployeeStatsController> {
  const EmployeeStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis estadísticas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.percent_rounded),
            tooltip: 'Comisiones',
            onPressed: () => Get.toNamed(GetRoutes.commissions),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Actualizar',
            onPressed: controller.refreshStats,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: controller.refreshStats,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 32),
          children: [
            Obx(() => DateRangeSelector(
                  selected: controller.range.value,
                  today: controller.today,
                  onChanged: controller.setRange,
                )),
            const SizedBox(height: 4),
            StatsSectionView(
              section: controller.stats,
              onRetry: controller.load,
              loadingMessage: 'Cargando tus estadísticas…',
              isEmpty: (stats) => stats.isEmpty,
              emptySubMessage: 'Prueba con un período más amplio.',
              builder: (context, stats) => EmployeeStatsWidget(stats: stats),
            ),
          ],
        ),
      ),
    );
  }
}
