import 'package:flutter/material.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/core/utils/formatters.dart';
import 'package:login_signup/features/services/domain/entities/service_entity.dart';
import 'package:login_signup/features/services/domain/entities/service_price_type.dart';
import 'package:login_signup/shared/utils/color_hex.dart';
import 'package:login_signup/shared/widgets/app_card.dart';
import 'package:login_signup/shared/widgets/app_pill.dart';

/// Tarjeta de un servicio (guía §3): el chip de su color de agenda, el
/// nombre, la duración y el precio formateado. Sin [onTap] es de solo
/// lectura (Employee). Inactivo = atenuado (no se puede agendar).
class ServiceCard extends StatelessWidget {
  final ServiceEntity service;
  final VoidCallback? onTap;

  /// Interruptor de activo (solo Owner); `null` = sin interruptor.
  final ValueChanged<bool>? onActiveChanged;

  const ServiceCard(
      {super.key, required this.service, this.onTap, this.onActiveChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = theme.textTheme;
    final tokens = context.tokens;
    final toggle = onActiveChanged;
    final variable = service.priceType == ServicePriceType.variable;
    return Opacity(
      opacity: service.isActive ? 1 : 0.55,
      child: AppCard(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
        depth: 1,
        onTap: onTap,
        semanticLabel: onTap == null ? null : 'Editar ${service.name}',
        child: Row(
          children: [
            ServiceColorChip(color: colorFromHex(service.color)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(service.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: text.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      AppPill(
                        dense: true,
                        tabular: true,
                        icon: Icons.schedule_rounded,
                        label: formatDurationMinutes(service.duration),
                      ),
                      if (variable)
                        AppPill(
                          dense: true,
                          icon: Icons.tune_rounded,
                          label: ServicePriceType.variable.apiValue,
                        ),
                      if (service.onlineBooking)
                        AppPill(
                          dense: true,
                          icon: Icons.public_rounded,
                          label: 'En línea',
                          colors: tokens.info,
                        ),
                      if (!service.isActive)
                        AppPill(
                          dense: true,
                          icon: Icons.pause_circle_rounded,
                          label: 'Inactivo',
                          colors: tokens.warning,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              formatCop(service.price),
              style: text.titleSmall
                  ?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w800,
                  )
                  .tabular,
            ),
            if (toggle != null)
              Switch(
                key: Key('service-active-${service.id}'),
                value: service.isActive,
                onChanged: toggle,
              ),
          ],
        ),
      ),
    );
  }
}

/// Muestra del color de un servicio en la agenda: un cuadro redondeado con
/// el degradado de ese color, brillo y el ícono legible encima. Los colores
/// de servicio son datos del negocio (no cambian con la paleta).
class ServiceColorChip extends StatelessWidget {
  final Color color;
  final double size;
  final IconData icon;

  const ServiceColorChip({
    super.key,
    required this.color,
    this.size = 44,
    this.icon = Icons.spa_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: tokens.gradientOf(color),
        borderRadius: AppRadii.fieldRadius,
        border: Border.all(color: tokens.innerBorder),
        boxShadow: tokens.elevation1(tint: color),
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: AppRadii.fieldRadius,
        gradient: tokens.sheenGradient,
      ),
      child: Icon(icon, size: size * 0.5, color: contrastOn(color)),
    );
  }
}
