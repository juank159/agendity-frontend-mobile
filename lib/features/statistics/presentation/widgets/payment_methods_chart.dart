import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import '../controllers/statistics_controller.dart';
import '../../domain/entities/payment_method_stats_entity.dart';

class PaymentMethodsChart extends StatelessWidget {
  PaymentMethodsChart({Key? key}) : super(key: key);

  final List<Color> chartColors = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.amber,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.orange,
    Colors.indigo,
    Colors.cyan,
  ];

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<StatisticsController>();

    return Obx(() {
      if (controller.isLoadingPaymentMethods.value &&
          controller.paymentMethodStats.isEmpty) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: CircularProgressIndicator(),
          ),
        );
      }

      if (controller.errorPaymentMethods.value.isNotEmpty &&
          controller.paymentMethodStats.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Text(
                  'Error: ${controller.errorPaymentMethods.value}',
                  style: TextStyle(color: Colors.red[700]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: controller.loadPaymentMethodStats,
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        );
      }

      // Si no hay datos cargados, cargarlos ahora
      if (controller.paymentMethodStats.isEmpty) {
        // Mostrar un botón para cargar los datos
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: ElevatedButton.icon(
              onPressed: controller.loadPaymentMethodStats,
              icon: const Icon(Icons.insights),
              label: const Text('Cargar datos de métodos de pago'),
            ),
          ),
        );
      }

      // Mostrar el gráfico y la tabla
      final stats = controller.paymentMethodStats;

      return Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Gráfico circular
              SizedBox(
                height: 220,
                child: Row(
                  children: [
                    // Gráfico
                    Expanded(
                      flex: 2,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 40,
                          sections: _getSections(stats),
                          pieTouchData: PieTouchData(
                            touchCallback:
                                (FlTouchEvent event, pieTouchResponse) {
                              // Implementar interacción si es necesario
                            },
                          ),
                        ),
                      ),
                    ),

                    // Leyenda
                    Expanded(
                      flex: 3,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: stats.take(5).map((stat) {
                          final index = stats.indexOf(stat);
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              children: [
                                Container(
                                  width: 14,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color:
                                        chartColors[index % chartColors.length],
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    stat.method,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                                Text(
                                  controller.formatPercent(stat.percentage),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Tabla de datos
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Desglose por método de pago',
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
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                    ),
                    children: const [
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          'Método',
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
                                child: Text(stat.method),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(stat.count.toString()),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  controller.formatCurrency(stat.total),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  controller.formatPercent(stat.percentage),
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

  List<PieChartSectionData> _getSections(List<PaymentMethodStatsEntity> stats) {
    return stats.asMap().entries.map((entry) {
      final index = entry.key;
      final stat = entry.value;

      return PieChartSectionData(
        color: chartColors[index % chartColors.length],
        value: stat.percentage,
        title: '', // Dejamos el título vacío para que se vea mejor
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }
}
