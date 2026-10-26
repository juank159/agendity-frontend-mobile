import 'package:flutter/material.dart';
import 'package:login_signup/core/utils/formatters.dart';
import 'package:login_signup/features/services/domain/entities/service_entity.dart';
import 'package:login_signup/features/services/domain/entities/service_price_type.dart';
import 'package:login_signup/features/services/presentation/widgets/color_picker.dart';

/// Tarjeta de un servicio. Sin [onTap] es de solo lectura (Employee).
class ServiceCard extends StatelessWidget {
  final ServiceEntity service;
  final VoidCallback? onTap;

  const ServiceCard({super.key, required this.service, this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final details = [
      formatDurationMinutes(service.duration),
      if (service.priceType == ServicePriceType.variable)
        ServicePriceType.variable.apiValue,
      if (!service.isActive) 'Inactivo',
    ].join(' · ');
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: colorFromHex(service.color),
            shape: BoxShape.circle,
          ),
        ),
        title: Text(service.name,
            style: text.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        subtitle: Text(details),
        trailing: Text(
          formatCop(service.price),
          style: text.titleSmall?.copyWith(
            color: scheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
