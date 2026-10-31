import 'package:flutter/material.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/features/appointments/domain/entities/appointment_entity.dart';
import 'package:login_signup/features/appointments/presentation/widgets/appointment_status_ui.dart';
import 'package:login_signup/shared/utils/color_hex.dart';

/// Un bloque de cita en el calendario: el fondo es el color del servicio
/// (dato del negocio) y la franja lateral, el estado de la cita (tema).
/// Una cita con varios servicios se pinta como bloques seguidos; el primero
/// lleva el nombre del cliente.
class AppointmentTile extends StatelessWidget {
  final AppointmentEntity appointment;
  final int serviceIndex;

  /// Vista de semana: solo el color, sin textos.
  final bool compact;

  /// Alto mínimo para pintar cliente y servicio en dos líneas.
  static const twoLineMinHeight = 34.0;

  const AppointmentTile({
    super.key,
    required this.appointment,
    this.serviceIndex = 0,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final a = appointment;
    final blocks = a.services.isEmpty ? 1 : a.services.length;
    final isFirst = serviceIndex == 0;
    final isLast = serviceIndex >= blocks - 1;
    final background = a.serviceColor(serviceIndex);
    final foreground = contrastOn(background);
    final stripe = a.isFullyPaid
        ? context.tokens.success.color
        : a.status.colorsOf(context).color;
    const radius = Radius.circular(6);
    final service = serviceIndex < a.services.length
        ? a.services[serviceIndex].name
        : '';

    final content = compact
        ? const SizedBox.expand()
        : LayoutBuilder(builder: (context, constraints) {
            // Un bloque de 15 min no tiene alto para dos líneas (7.04-2):
            // cliente y servicio van en una sola.
            final oneLine = constraints.maxHeight < twoLineMinHeight;
            final clientStyle = TextStyle(
              color: foreground,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              decoration: a.isCancelled ? TextDecoration.lineThrough : null,
            );
            final serviceStyle = TextStyle(color: foreground, fontSize: 10);
            final List<Widget> lines;
            if (oneLine) {
              lines = [
                Text.rich(
                  TextSpan(children: [
                    if (isFirst) TextSpan(text: a.clientName, style: clientStyle),
                    if (isFirst && service.isNotEmpty)
                      TextSpan(text: ' · ', style: serviceStyle),
                    if (service.isNotEmpty)
                      TextSpan(text: service, style: serviceStyle),
                  ]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ];
            } else {
              lines = [
                if (isFirst)
                  Text(a.clientName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: clientStyle),
                if (service.isNotEmpty)
                  Text(service,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: serviceStyle),
              ];
            }
            return Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: 6, vertical: oneLine ? 0 : 2),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: lines,
                    ),
                  ),
                  if (isFirst && a.needsReschedule)
                    Padding(
                      padding: const EdgeInsets.only(left: 2),
                      child: Icon(Icons.report_problem_outlined,
                          size: 14,
                          color: foreground,
                          semanticLabel: 'Por mover'),
                    ),
                  if (isFirst && a.isWebBooking)
                    Padding(
                      padding: const EdgeInsets.only(left: 2),
                      child: Icon(Icons.public,
                          size: 13,
                          color: foreground,
                          semanticLabel: 'Reserva web'),
                    ),
                  if (isFirst && a.isFullyPaid)
                    Icon(Icons.check_circle,
                        size: 14, color: foreground, semanticLabel: 'Pagada'),
                ],
              ),
            );
          });

    return Semantics(
      label: '${a.clientName}, $service, ${a.status.label}'
          '${a.isWebBooking ? ', reserva web' : ''}'
          '${a.needsReschedule ? ', por mover' : ''}',
      child: Padding(
        padding:
            EdgeInsets.symmetric(horizontal: 1, vertical: blocks > 1 ? 0 : 1),
        child: ClipRRect(
          borderRadius: BorderRadius.vertical(
            top: isFirst ? radius : Radius.zero,
            bottom: isLast ? radius : Radius.zero,
          ),
          child: ColoredBox(
            color: a.isCancelled
                ? background.withValues(alpha: 0.45)
                : background,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(width: 5, child: ColoredBox(color: stripe)),
                Expanded(child: content),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
