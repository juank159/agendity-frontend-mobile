// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:fl_chart/fl_chart.dart';
// import '../controllers/statistics_controller.dart';

// class ProfessionalsPerformanceWidget extends StatelessWidget {
//   const ProfessionalsPerformanceWidget({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     final controller = Get.find<StatisticsController>();

//     return Obx(() {
//       if (controller.isLoadingProfessionals.value &&
//           controller.professionalStats.isEmpty) {
//         return const Center(
//           child: Padding(
//             padding: EdgeInsets.all(20.0),
//             child: CircularProgressIndicator(),
//           ),
//         );
//       }

//       if (controller.errorProfessionals.value.isNotEmpty &&
//           controller.professionalStats.isEmpty) {
//         return Center(
//           child: Padding(
//             padding: const EdgeInsets.all(20.0),
//             child: Column(
//               children: [
//                 Text(
//                   'Error: ${controller.errorProfessionals.value}',
//                   style: TextStyle(color: Colors.red[700]),
//                   textAlign: TextAlign.center,
//                 ),
//                 const SizedBox(height: 10),
//                 ElevatedButton(
//                   onPressed: controller.loadProfessionalStats,
//                   child: const Text('Reintentar'),
//                 ),
//               ],
//             ),
//           ),
//         );
//       }

//       if (controller.professionalStats.isEmpty) {
//         return Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(Icons.info_outline, size: 48, color: Colors.grey),
//               const SizedBox(height: 16),
//               Text(
//                 'No hay datos de profesionales para el período seleccionado',
//                 textAlign: TextAlign.center,
//                 style: TextStyle(color: Colors.grey[700]),
//               ),
//               const SizedBox(height: 20),
//               ElevatedButton.icon(
//                 onPressed: controller.loadProfessionalStats,
//                 icon: const Icon(Icons.refresh),
//                 label: const Text('Actualizar'),
//               ),
//             ],
//           ),
//         );
//       }

//       // Mostrar el gráfico de barras y la tabla
//       final stats = controller.professionalStats;

//       return Card(
//         elevation: 2,
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             children: [
//               // Gráfico de barras
//               SizedBox(
//                 height: 220,
//                 child: BarChart(
//                   BarChartData(
//                     alignment: BarChartAlignment.spaceAround,
//                     maxY: stats
//                             .map((e) => e.totalAmount)
//                             .reduce((a, b) => a > b ? a : b) *
//                         1.2,
//                     titlesData: FlTitlesData(
//                       show: true,
//                       bottomTitles: AxisTitles(
//                         sideTitles: SideTitles(
//                           showTitles: true,
//                           getTitlesWidget: (value, meta) {
//                             if (value >= 0 && value < stats.length) {
//                               return Padding(
//                                 padding: const EdgeInsets.only(top: 8.0),
//                                 child: Text(
//                                   stats[value.toInt()]
//                                       .professionalName
//                                       .split(' ')[0],
//                                   style: const TextStyle(fontSize: 10),
//                                 ),
//                               );
//                             }
//                             return const SizedBox();
//                           },
//                         ),
//                       ),
//                       leftTitles: AxisTitles(
//                         sideTitles: SideTitles(
//                           showTitles: true,
//                           reservedSize: 70, // Aumentamos un poco el espacio
//                           getTitlesWidget: (value, meta) {
//                             // Formateamos con $ a la izquierda
//                             final formattedValue =
//                                 controller.formatCurrency(value);
//                             return Padding(
//                               padding: const EdgeInsets.only(right: 8.0),
//                               child: Text(
//                                 formattedValue,
//                                 style: const TextStyle(fontSize: 10),
//                               ),
//                             );
//                           },
//                         ),
//                       ),
//                       topTitles: const AxisTitles(
//                         sideTitles: SideTitles(showTitles: false),
//                       ),
//                       rightTitles: const AxisTitles(
//                         sideTitles: SideTitles(showTitles: false),
//                       ),
//                     ),
//                     borderData: FlBorderData(show: false),
//                     barGroups: stats.asMap().entries.map((entry) {
//                       final index = entry.key;
//                       final stat = entry.value;

//                       return BarChartGroupData(
//                         x: index,
//                         barRods: [
//                           BarChartRodData(
//                             toY: stat.totalAmount,
//                             color: Theme.of(context).primaryColor,
//                             width: 15,
//                             borderRadius: const BorderRadius.only(
//                               topLeft: Radius.circular(6),
//                               topRight: Radius.circular(6),
//                             ),
//                           ),
//                         ],
//                       );
//                     }).toList(),
//                   ),
//                 ),
//               ),

//               const SizedBox(height: 20),

//               // Tabla de datos
//               const Align(
//                 alignment: Alignment.centerLeft,
//                 child: Text(
//                   'Rendimiento por profesional',
//                   style: TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 10),

//               Table(
//                 columnWidths: const {
//                   0: FlexColumnWidth(3),
//                   1: FlexColumnWidth(1),
//                   2: FlexColumnWidth(1.5),
//                   3: FlexColumnWidth(1.5),
//                 },
//                 border: TableBorder.all(
//                   color: Colors.grey.shade300,
//                   width: 1,
//                 ),
//                 children: [
//                   TableRow(
//                     decoration: BoxDecoration(
//                       color: Theme.of(context).primaryColor.withOpacity(0.1),
//                     ),
//                     children: const [
//                       Padding(
//                         padding: EdgeInsets.all(8.0),
//                         child: Text(
//                           'Profesional',
//                           style: TextStyle(fontWeight: FontWeight.bold),
//                         ),
//                       ),
//                       Padding(
//                         padding: EdgeInsets.all(8.0),
//                         child: Text(
//                           'Citas', // Cambiado de "Citas" a una sola línea
//                           style: TextStyle(fontWeight: FontWeight.bold),
//                           textAlign: TextAlign.center, // Centramos el texto
//                         ),
//                       ),
//                       Padding(
//                         padding: EdgeInsets.all(8.0),
//                         child: Text(
//                           'Total',
//                           style: TextStyle(fontWeight: FontWeight.bold),
//                           textAlign: TextAlign.right,
//                         ),
//                       ),
//                       Padding(
//                         padding: EdgeInsets.all(8.0),
//                         child: Text(
//                           'Promedio', // Cambiado de "Promedio" a una sola línea
//                           style: TextStyle(fontWeight: FontWeight.bold),
//                           textAlign: TextAlign.right,
//                         ),
//                       ),
//                     ],
//                   ),
//                   ...stats
//                       .map((stat) => TableRow(
//                             children: [
//                               Padding(
//                                 padding: const EdgeInsets.all(8.0),
//                                 child: Text(stat.professionalName),
//                               ),
//                               Padding(
//                                 padding: const EdgeInsets.all(8.0),
//                                 child: Text(
//                                   stat.appointmentCount.toString(),
//                                   textAlign:
//                                       TextAlign.center, // Centramos el valor
//                                 ),
//                               ),
//                               Padding(
//                                 padding: const EdgeInsets.all(8.0),
//                                 child: Text(
//                                   controller.formatCurrency(stat.totalAmount),
//                                   textAlign: TextAlign.right,
//                                 ),
//                               ),
//                               Padding(
//                                 padding: const EdgeInsets.all(8.0),
//                                 child: Text(
//                                   controller
//                                       .formatCurrency(stat.averagePerPayment),
//                                   textAlign: TextAlign.right,
//                                 ),
//                               ),
//                             ],
//                           ))
//                       .toList(),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       );
//     });
//   }
// }

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../controllers/statistics_controller.dart';

class ProfessionalsPerformanceWidget extends StatelessWidget {
  const ProfessionalsPerformanceWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<StatisticsController>();

    return Obx(() {
      if (controller.isLoadingProfessionals.value &&
          controller.professionalStats.isEmpty) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: CircularProgressIndicator(),
          ),
        );
      }

      if (controller.errorProfessionals.value.isNotEmpty &&
          controller.professionalStats.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Text(
                  'Error: ${controller.errorProfessionals.value}',
                  style: TextStyle(color: Colors.red[700]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: controller.loadProfessionalStats,
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        );
      }

      if (controller.professionalStats.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'No hay datos de profesionales para el período seleccionado',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[700]),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: controller.loadProfessionalStats,
                icon: const Icon(Icons.refresh),
                label: const Text('Actualizar'),
              ),
            ],
          ),
        );
      }

      // Mostrar el gráfico de barras y la tabla
      final stats = controller.professionalStats;

      return Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Gráfico de barras
              SizedBox(
                height: 220,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: stats
                            .map((e) => e.totalAmount)
                            .reduce((a, b) => a > b ? a : b) *
                        1.2,
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            if (value >= 0 && value < stats.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  stats[value.toInt()]
                                      .professionalName
                                      .split(' ')[0],
                                  style: const TextStyle(fontSize: 10),
                                ),
                              );
                            }
                            return const SizedBox();
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 80,
                          getTitlesWidget: (value, meta) {
                            // Formato con $ a la izquierda
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Text(
                                '\$ ${NumberFormat('#,###', 'es_CO').format(value)}',
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
                    borderData: FlBorderData(show: false),
                    barGroups: stats.asMap().entries.map((entry) {
                      final index = entry.key;
                      final stat = entry.value;

                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: stat.totalAmount,
                            color: Theme.of(context).primaryColor,
                            width: 15,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(6),
                              topRight: Radius.circular(6),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Título de la sección
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Rendimiento por profesional',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Tabla personalizada
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  children: [
                    // Encabezado de la tabla
                    Container(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text(
                                'Profesional',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Center(
                              child: Text(
                                'Citas',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Text(
                                'Total',
                                style: TextStyle(fontWeight: FontWeight.bold),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Text(
                                'Promedio',
                                style: TextStyle(fontWeight: FontWeight.bold),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Filas de datos
                    ...stats.map((stat) {
                      return Container(
                        decoration: BoxDecoration(
                          border: Border(
                              top: BorderSide(color: Colors.grey.shade300)),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Text(stat.professionalName),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Center(
                                child: Text(
                                  stat.appointmentCount.toString(),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: Text(
                                  '\$ ${NumberFormat('#,###', 'es_CO').format(stat.totalAmount)}',
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: Text(
                                  '\$ ${NumberFormat('#,###', 'es_CO').format(stat.averagePerPayment)}',
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
