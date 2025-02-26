import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../domain/entities/payment_stats_entity.dart';
import '../controllers/statistics_controller.dart';

class OverviewStatsCard extends StatelessWidget {
  final PaymentStatsEntity stats;

  const OverviewStatsCard({
    Key? key,
    required this.stats,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<StatisticsController>();

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Resumen de ventas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Total de ventas
            _buildStatRow(
              context,
              'Total de ventas',
              controller.formatCurrency(stats.totalAmount),
              Icons.monetization_on,
              Colors.green,
            ),
            const SizedBox(height: 12),

            // Número de transacciones
            _buildStatRow(
              context,
              'Transacciones',
              stats.paymentCount.toString(),
              Icons.receipt_long,
              Colors.blue,
            ),
            const SizedBox(height: 12),

            // Valor promedio
            _buildStatRow(
              context,
              'Valor promedio',
              controller.formatCurrency(stats.averageAmount),
              Icons.analytics,
              Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: color,
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
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
        ),
      ],
    );
  }
}
