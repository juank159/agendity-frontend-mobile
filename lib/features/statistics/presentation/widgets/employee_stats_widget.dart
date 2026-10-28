import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/statistics_controller.dart';

class EmployeeStatsWidget extends StatelessWidget {
  final controller = Get.find<StatisticsController>();

  EmployeeStatsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoadingEmployeeStats.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.errorEmployeeStats.value.isNotEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                'Error al cargar estadísticas',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(controller.errorEmployeeStats.value),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: controller.loadEmployeeStats,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        );
      }

      final stats = controller.employeeStats.value;
      if (stats == null) {
        return const Center(
          child: Text('No hay datos disponibles para este período'),
        );
      }

      // Extraer datos del resumen
      final totalAmount = stats.summary.totalAmount;
      final paymentCount = stats.summary.paymentCount;
      final appointmentCount = stats.summary.appointmentCount;
      final averagePerPayment = stats.summary.averagePerPayment;

      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tarjeta de resumen
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Resumen de ganancias',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatItem(
                            'Total Ganancias',
                            controller.formatCurrency(
                                totalAmount.toDouble()), // Convertir a double
                            Icons.monetization_on,
                            Colors.green,
                          ),
                        ),
                        Expanded(
                          child: _buildStatItem(
                            'Pagos',
                            paymentCount.toString(),
                            Icons.payment,
                            Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatItem(
                            'Citas',
                            appointmentCount.toString(),
                            Icons.calendar_today,
                            Colors.orange,
                          ),
                        ),
                        Expanded(
                          child: _buildStatItem(
                            'Promedio',
                            controller.formatCurrency(averagePerPayment),
                            Icons.trending_up,
                            Colors.purple,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Rendimiento por servicio
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Servicios Realizados',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (stats.byService.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                              'No hay servicios registrados en este período'),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: stats.byService.length,
                        itemBuilder: (context, index) {
                          final service = stats.byService[index];
                          return ListTile(
                            title: Text(service.serviceName.isEmpty
                                ? 'Servicio'
                                : service.serviceName),
                            subtitle: Text('${service.count} servicios'),
                            trailing: Text(
                              controller.formatCurrency(service.total),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Evolución diaria
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Evolución Diaria',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (stats.dailyEvolution.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('No hay datos diarios en este período'),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: stats.dailyEvolution.length,
                        itemBuilder: (context, index) {
                          final day = stats.dailyEvolution[index];
                          final formattedDate =
                              DateFormat('dd/MM/yyyy').format(day.day);
                          return ListTile(
                            title: Text(formattedDate),
                            subtitle: Text('${day.count} citas'),
                            trailing: Text(
                              controller.formatCurrency(day.total),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
