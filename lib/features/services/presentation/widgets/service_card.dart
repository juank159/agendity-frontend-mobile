import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_styles.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/service_entity.dart';

class ServiceCard extends StatelessWidget {
  final ServiceEntity service;

  const ServiceCard({
    required this.service,
    super.key,
  });

  String _formatDuration(int minutes) {
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      return '$hours h ${remainingMinutes}min';
    }
    return '$minutes min';
  }

  String _formatPrice(String price) {
    return NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$ ',
      decimalDigits: 0,
      customPattern: '\u00A4#,##0',
    ).format(double.parse(price));
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: AppStyles.cardShape,
      elevation: 2,
      child: ListTile(
        contentPadding: AppStyles.cardPadding,
        leading: Container(
          width: 12,
          height: 12,
          decoration: const BoxDecoration(
            color: AppColors.cardIndicator,
            shape: BoxShape.circle,
          ),
        ),
        title: Text(
          service.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          _formatDuration(service.duration),
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        trailing: Text(
          _formatPrice(service.price),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: AppColors.primary,
          ),
        ),
        onTap: () => Get.toNamed('/service-details', arguments: service),
      ),
    );
  }
}
