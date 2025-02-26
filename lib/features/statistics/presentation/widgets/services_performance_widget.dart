import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import '../controllers/statistics_controller.dart';

class ServicesPerformanceWidget extends StatelessWidget {
  const ServicesPerformanceWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<StatisticsController>();

    return Obx(() {
      if (controller.isLoadingServices.value &&
          controller.serviceStats.isEmpty) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: CircularProgressIndicator(),
          ),
        );
      }

      if (controller.errorServices.value.isNotEmpty &&
          controller.serviceStats.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Text(
                  'Error: ${controller.errorServices.value}',
                  style: TextStyle(color: Colors.red[700]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: controller.loadServiceStats,
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        );
      }

      // Si no hay datos cargados, cargarlos ahora
      if (controller.serviceStats.isEmpty) {
        // Mostrar un botón para cargar los datos
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: ElevatedButton.icon(
              onPressed: controller.loadServiceStats,
              icon: const Icon(Icons.bar_chart),
              label: const Text('Cargar datos de servicios'),
            ),
          ),
        );
      }

      // Mostrar el gráfico horizontal y la tabla
      final stats = controller.serviceStats;

      return Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Gráfico de barras horizontales
              SizedBox(
                height: 300,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: stats.length.toDouble(),
                    barTouchData: BarTouchData(enabled: false),
                    titlesData: FlTitlesData(
                      show: true,
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            if (value >= 0 && value < stats.length) {
                              final stat = stats[value.toInt()];
                              return SideTitleWidget(
                                axisSide: meta.axisSide,
                                child: Text(
                                  stat.serviceName.length > 20
                                      ? '${stat.serviceName.substring(0, 17)}...'
                                      : stat.serviceName,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              );
                            }
                            return const SizedBox();
                          },
                          reservedSize: 120,
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 5.0),
                              child: Text(
                                controller.formatCurrency(value),
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          },
                        ),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    barGroups: stats.asMap().entries.map((entry) {
                      final index = entry.key;
                      final stat = entry.value;

                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: stat.totalAmount,
                            color: Colors.greenAccent.shade700,
                            width: 20,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                  swapAnimationDuration: const Duration(milliseconds: 150),
                  swapAnimationCurve: Curves.linear,
                ),
              ),

              const SizedBox(height: 20),

              // Tabla de datos
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Rendimiento por servicio',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              Table(
                columnWidths: const {
                  0: FlexColumnWidth(3),
                  1: FlexColumnWidth(1),
                  2: FlexColumnWidth(2),
                  3: FlexColumnWidth(1),
                },
                border: TableBorder.all(
                  color: Colors.grey.shade300,
                  width: 1,
                ),
                children: [
                  TableRow(
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                    ),
                    children: const [
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          'Servicio',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          'Cant.',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          'Total',
                          style: TextStyle(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.right,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          '%',
                          style: TextStyle(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                  ...stats
                      .map((stat) => TableRow(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(stat.serviceName),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(stat.paymentCount.toString()),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  controller.formatCurrency(stat.totalAmount),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  controller
                                      .formatPercent(stat.percentageOfTotal),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ],
                          ))
                      .toList(),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }
}
