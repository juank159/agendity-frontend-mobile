// lib/features/statistics/presentation/screens/employee_stats_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/statistics_controller.dart';
import '../widgets/date_range_selector.dart';
import '../widgets/employee_stats_widget.dart';

class EmployeeStatsScreen extends StatelessWidget {
  const EmployeeStatsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<StatisticsController>();

    // Cargar específicamente las estadísticas de empleado
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadEmployeeStats();
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Estadísticas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: controller.loadEmployeeStats,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => controller.loadEmployeeStats(),
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

              // Widget de estadísticas de empleado
              EmployeeStatsWidget(),
            ],
          ),
        ),
      ),
    );
  }
}
