import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
            onPressed: controller.refreshStats,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: controller.refreshStats,
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
