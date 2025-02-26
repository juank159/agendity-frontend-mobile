import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../domain/entities/payment_comparison_entity.dart';
import '../controllers/statistics_controller.dart';

class PaymentComparisonCard extends StatelessWidget {
  final PaymentComparisonEntity comparison;

  const PaymentComparisonCard({
    Key? key,
    required this.comparison,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<StatisticsController>();
    final change = comparison.change;

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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Período actual: ${controller.formatDate(comparison.currentPeriod.startDate)} - ${controller.formatDate(comparison.currentPeriod.endDate)}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Período anterior: ${controller.formatDate(comparison.previousPeriod.startDate)} - ${controller.formatDate(comparison.previousPeriod.endDate)}',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
              ),
            ),
            const Divider(height: 24),

            // Ventas
            _buildComparisonRow(
              context,
              'Ventas',
              controller.formatCurrency(comparison.currentPeriod.totalAmount),
              controller.formatCurrency(comparison.previousPeriod.totalAmount),
              change.amountPercentage,
              controller.getPercentageColor(change.amountPercentage),
              controller.getPercentageIcon(change.amountPercentage),
            ),
            const SizedBox(height: 16),

            // Transacciones
            _buildComparisonRow(
              context,
              'Transacciones',
              comparison.currentPeriod.paymentCount.toString(),
              comparison.previousPeriod.paymentCount.toString(),
              change.countPercentage,
              controller.getPercentageColor(change.countPercentage),
              controller.getPercentageIcon(change.countPercentage),
            ),
            const SizedBox(height: 16),

            // Valor promedio
            _buildComparisonRow(
              context,
              'Valor promedio',
              controller.formatCurrency(comparison.currentPeriod.averageAmount),
              controller
                  .formatCurrency(comparison.previousPeriod.averageAmount),
              change.averagePercentage,
              controller.getPercentageColor(change.averagePercentage),
              controller.getPercentageIcon(change.averagePercentage),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonRow(
    BuildContext context,
    String label,
    String currentValue,
    String previousValue,
    double percentageChange,
    Color changeColor,
    IconData changeIcon,
  ) {
    final controller = Get.find<StatisticsController>();

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                currentValue,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Anterior: $previousValue',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: changeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  changeIcon,
                  color: changeColor,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  controller.formatPercent(percentageChange.abs()),
                  style: TextStyle(
                    color: changeColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
