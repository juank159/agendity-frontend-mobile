import 'package:flutter/material.dart';
import 'package:login_signup/core/utils/formatters.dart';
import 'package:login_signup/features/services/domain/entities/service_entity.dart';
import 'package:login_signup/features/services/domain/entities/service_price_type.dart';
import 'package:login_signup/shared/utils/color_hex.dart';

/// Tarjeta de un servicio. Sin [onTap] es de solo lectura (Employee).
class ServiceCard extends StatelessWidget {
  final ServiceEntity service;
  final VoidCallback? onTap;

  /// Interruptor de activo (solo Owner); `null` = sin interruptor.
  final ValueChanged<bool>? onActiveChanged;

  const ServiceCard(
      {super.key, required this.service, this.onTap, this.onActiveChanged});

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
    final price = Text(
      formatCop(service.price),
      style: text.titleSmall?.copyWith(
        color: scheme.primary,
        fontWeight: FontWeight.bold,
      ),
    );
    final toggle = onActiveChanged;
    return Opacity(
      // Inactivo: atenuado (no se puede agendar).
      opacity: service.isActive ? 1 : 0.55,
      child: Card(
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
          trailing: toggle == null
              ? price
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    price,
                    Switch(
                      key: Key('service-active-${service.id}'),
                      value: service.isActive,
                      onChanged: toggle,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
