import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_styles.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/service_entity.dart';

// class ServiceCard extends StatelessWidget {
//   final ServiceEntity service;

//   const ServiceCard({
//     required this.service,
//     super.key,
//   });

//   String _formatDuration(int minutes) {
//     if (minutes >= 60) {
//       final hours = minutes ~/ 60;
//       final remainingMinutes = minutes % 60;
//       return '$hours h ${remainingMinutes}min';
//     }
//     return '$minutes min';
//   }

//   String _formatPrice(double price) {
//     // Cambiado aquí
//     return NumberFormat.currency(
//       locale: 'es_CO',
//       symbol: '\$ ',
//       decimalDigits: 0,
//       customPattern: '\u00A4#,##0',
//     ).format(price);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       margin: const EdgeInsets.only(bottom: 12),
//       shape: AppStyles.cardShape,
//       elevation: 2,
//       child: ListTile(
//         contentPadding: AppStyles.cardPadding,
//         leading: Container(
//           width: 12,
//           height: 12,
//           decoration: const BoxDecoration(
//             color: service.color,
//             shape: BoxShape.circle,
//           ),
//         ),
//         title: Text(
//           service.name,
//           style: const TextStyle(
//             fontWeight: FontWeight.bold,
//             fontSize: 16,
//           ),
//         ),
//         subtitle: Text(
//           _formatDuration(service.duration),
//           style: TextStyle(
//             color: Colors.grey[600],
//             fontSize: 14,
//           ),
//         ),
//         trailing: Text(
//           _formatPrice(
//               service.price), // Aquí ya no hay error porque price es double
//           style: const TextStyle(
//             fontWeight: FontWeight.bold,
//             fontSize: 16,
//             color: AppColors.primary,
//           ),
//         ),
//         onTap: () => Get.toNamed('/service-details', arguments: service),
//       ),
//     );
//   }
// }

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

  String _formatPrice(double price) {
    return NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$ ',
      decimalDigits: 0,
      customPattern: '\u00A4#,##0',
    ).format(price);
  }

  Color _parseColor(String colorString) {
    // Convertir un color hexadecimal (#RRGGBB) en un objeto Color
    return Color(int.parse(colorString.substring(1), radix: 16) + 0xFF000000);
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
          decoration: BoxDecoration(
            color: _parseColor(service.color), // Convertir color aquí
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
