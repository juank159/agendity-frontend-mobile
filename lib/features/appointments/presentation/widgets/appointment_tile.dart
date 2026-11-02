import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:login_signup/core/config/color_contrast.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/core/utils/formatters.dart';
import 'package:login_signup/core/widgets/app_pressable.dart';
import 'package:login_signup/features/appointments/domain/entities/appointment_entity.dart';
import 'package:login_signup/features/appointments/presentation/widgets/appointment_status_ui.dart';
import 'package:login_signup/shared/widgets/app_avatar.dart';
import 'package:login_signup/shared/widgets/status_chip.dart';

/// Tarjeta "3D" de una cita en la agenda (12.04, guía §4): **una por cita**,
/// ocupa todo su intervalo de tiempo.
///
/// - Fondo: degradado del color del primer servicio (dato del negocio), con
///   brillo superior, borde interior claro y sombra teñida; se encoge al
///   pulsar (el toque lo maneja el calendario).
/// - Texto blanco o negro según el contraste con ese color.
/// - Contenido según el alto: hora, cliente, una píldora por servicio, estado,
///   pago e iniciales de la profesional; en citas cortas, una línea
///   (hora · cliente · primer servicio +N).
/// - "Por mover" (`needsReschedule`): borde punteado del color de aviso.
class AppointmentTile extends StatelessWidget {
  final AppointmentEntity appointment;

  /// Vista de semana: columna estrecha, solo el nombre del cliente.
  final bool compact;

  /// Por debajo de este alto, una sola línea (un bloque de 15 min, 7.04-2).
  static const twoLineMinHeight = 34.0;

  /// Desde este alto: hora, cliente y píldoras de servicios (30 min).
  static const fullMinHeight = 62.0;

  /// Ancho mínimo para las insignias (pago, profesional…).
  static const badgesMinWidth = 150.0;

  /// Desde este alto, además, el chip de estado.
  static const statusMinHeight = 100.0;

  const AppointmentTile({
    super.key,
    required this.appointment,
    this.compact = false,
  });

  static const Color _ink = textInk;
  static const Color _white = textWhite;

  /// Cuánto se puede oscurecer (luminosidad HSL) el color de un servicio
  /// para poner el texto en blanco sin que deje de parecerse al elegido.
  static const maxDarkening = 0.15;

  /// Colores de la tarjeta para el color de un servicio, siempre con
  /// contraste AA (4,5:1) en todo el degradado:
  /// - blanco si basta con oscurecer el color como mucho [maxDarkening]
  ///   (mismo tono): las tarjetas se ven vivas;
  /// - si no, casi negro sobre el color tal cual (colores claros);
  /// - si ni así, blanco sobre el color oscurecido lo necesario.
  static ({Color base, Color foreground}) colorsFor(Color service) {
    final original = HSLColor.fromColor(service);
    var hsl = original;
    var darkened = service;
    while (contrastRatio(_white, _lighter(darkened)) < contrastAA &&
        hsl.lightness > 0) {
      hsl = hsl.withLightness((hsl.lightness - 0.01).clamp(0.0, 1.0));
      darkened = hsl.toColor();
    }
    final drop = original.lightness - hsl.lightness;
    if (drop > maxDarkening + 1e-9 &&
        contrastRatio(_ink, service) >= contrastAA) {
      return (base: service, foreground: _ink);
    }
    return (base: darkened, foreground: _white);
  }

  /// Esquina clara del degradado (= `AppTokens.gradientOf`).
  static Color _lighter(Color base) => Color.lerp(base, _white, 0.18)!;

  String get _semanticLabel {
    final a = appointment;
    return [
      a.clientName,
      ...a.serviceNames,
      formatTimeRange(a.startTime, a.endTime),
      a.status.label,
      a.paymentStatus.label,
      if (a.professionalName != null) 'con ${a.professionalName}',
      if (a.isWebBooking) 'reserva web',
      if (a.needsReschedule) 'por mover',
    ].join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final a = appointment;
    final colors = colorsFor(a.primaryColor);
    final base = colors.base;
    final foreground = colors.foreground;
    final radius = BorderRadius.circular(compact ? 8 : AppRadii.chip);
    final warning = tokens.warning.color;

    return Semantics(
      label: _semanticLabel,
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
        child: AppPressable(
          child: Opacity(
            opacity: a.isCancelled ? 0.55 : 1,
            child: LayoutBuilder(builder: (context, constraints) {
              final short = constraints.maxHeight < fullMinHeight;
              return DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: radius,
                  boxShadow: compact || short
                      ? tokens.elevation1(tint: base)
                      : tokens.elevation2(tint: base),
                ),
                child: ClipRRect(
                  borderRadius: radius,
                  child: DecoratedBox(
                    decoration:
                        BoxDecoration(gradient: tokens.gradientOf(base)),
                    position: DecorationPosition.background,
                    child: DecoratedBox(
                      position: DecorationPosition.foreground,
                      decoration: BoxDecoration(
                        borderRadius: radius,
                        border: a.needsReschedule
                            ? null
                            : Border.all(color: tokens.innerBorder),
                      ),
                      child: CustomPaint(
                        foregroundPainter: a.needsReschedule
                            ? _DashedBorderPainter(
                                color: warning, radius: radius)
                            : null,
                        child: DecoratedBox(
                          decoration:
                              BoxDecoration(gradient: tokens.sheenGradient),
                          child: SizedBox.expand(
                            child: _content(context, constraints, foreground),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _content(
      BuildContext context, BoxConstraints constraints, Color foreground) {
    final height = constraints.maxHeight;
    // En una columna estrecha (citas que se solapan) no caben las insignias.
    final badges = constraints.maxWidth >= badgesMinWidth;
    final Widget body;
    if (compact) {
      body = _WeekContent(appointment: appointment, foreground: foreground);
    } else if (height < twoLineMinHeight) {
      body = _OneLine(
          appointment: appointment, foreground: foreground, badges: badges);
    } else if (height < fullMinHeight) {
      body = _TwoLines(
          appointment: appointment, foreground: foreground, badges: badges);
    } else {
      body = _Full(
        appointment: appointment,
        foreground: foreground,
        badges: badges,
        showStatus: badges && height >= statusMinHeight,
      );
    }
    // Lo que no quepa se recorta (nunca un overflow de Flex).
    return ClipRect(
      child: OverflowBox(
        alignment: Alignment.topLeft,
        minHeight: 0,
        maxHeight: double.infinity,
        child: body,
      ),
    );
  }
}

/// Estilos de texto de la tarjeta sobre el color del servicio.
class _TileText {
  final Color foreground;
  final bool cancelled;

  const _TileText(this.foreground, {this.cancelled = false});

  TextStyle client(double size) => TextStyle(
        color: foreground,
        fontSize: size,
        fontWeight: FontWeight.w800,
        height: 1.15,
        decoration: cancelled ? TextDecoration.lineThrough : null,
        decorationColor: foreground,
      );

  TextStyle detail(double size, {FontWeight weight = FontWeight.w600}) =>
      TextStyle(
        color: foreground.withValues(alpha: 0.9),
        fontSize: size,
        fontWeight: weight,
        height: 1.15,
      ).tabular;
}

/// "Pestañas +2": el primer servicio y cuántos más.
String _servicesSummary(AppointmentEntity a) {
  if (a.services.isEmpty) return '';
  final more = a.services.length - 1;
  return more == 0 ? a.services.first.name : '${a.services.first.name} +$more';
}

/// Vista de semana: el nombre del cliente si cabe.
class _WeekContent extends StatelessWidget {
  final AppointmentEntity appointment;
  final Color foreground;

  const _WeekContent({required this.appointment, required this.foreground});

  @override
  Widget build(BuildContext context) {
    final a = appointment;
    final text = _TileText(foreground, cancelled: a.isCancelled);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 3, 3, 2),
      child: Text(
        a.client.name.trim().isEmpty ? a.clientName : a.client.name.trim(),
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.fade,
        style: text.client(9.5),
      ),
    );
  }
}

/// Cita corta (menos de [AppointmentTile.twoLineMinHeight]): una línea.
class _OneLine extends StatelessWidget {
  final AppointmentEntity appointment;
  final Color foreground;

  final bool badges;

  const _OneLine({
    required this.appointment,
    required this.foreground,
    required this.badges,
  });

  @override
  Widget build(BuildContext context) {
    final a = appointment;
    final text = _TileText(foreground, cancelled: a.isCancelled);
    final services = _servicesSummary(a);
    final dot = Text(' · ', style: text.detail(10.5));
    if (!badges) {
      // Columna estrecha: solo el cliente.
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Text(a.clientName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: text.client(11)),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Row(
        children: [
          Flexible(
            child: Text(formatTime(a.startTime),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.detail(10.5)),
          ),
          dot,
          Flexible(
            flex: 2,
            child: Text(a.clientName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.client(11)),
          ),
          if (services.isNotEmpty) ...[
            dot,
            Flexible(
              child: Text(services,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.detail(10.5, weight: FontWeight.w500)),
            ),
          ],
          if (badges) ...[
            const SizedBox(width: 4),
            _Badges(appointment: a, foreground: foreground, size: 14),
          ],
        ],
      ),
    );
  }
}

/// Cita de 15 a 30 min: cliente con insignias y, debajo, hora y servicios.
class _TwoLines extends StatelessWidget {
  final AppointmentEntity appointment;
  final Color foreground;

  final bool badges;

  const _TwoLines({
    required this.appointment,
    required this.foreground,
    required this.badges,
  });

  @override
  Widget build(BuildContext context) {
    final a = appointment;
    final text = _TileText(foreground, cancelled: a.isCancelled);
    final services = _servicesSummary(a);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 3, 6, 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(a.clientName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.client(12)),
              ),
              if (badges)
                _Badges(appointment: a, foreground: foreground, size: 15),
            ],
          ),
          const SizedBox(height: 1),
          Text(
            services.isEmpty
                ? formatTimeRange(a.startTime, a.endTime)
                : '${formatTimeRange(a.startTime, a.endTime)} · $services',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: text.detail(10.5, weight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

/// Cita de 30 min o más: hora, cliente, píldoras de servicios y estado.
class _Full extends StatelessWidget {
  final AppointmentEntity appointment;
  final Color foreground;
  final bool showStatus;
  final bool badges;

  const _Full({
    required this.appointment,
    required this.foreground,
    required this.badges,
    required this.showStatus,
  });

  @override
  Widget build(BuildContext context) {
    final a = appointment;
    final text = _TileText(foreground, cancelled: a.isCancelled);
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 6, 8, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(formatTimeRange(a.startTime, a.endTime),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.detail(11)),
              ),
              if (badges)
                _Badges(appointment: a, foreground: foreground, size: 18),
            ],
          ),
          const SizedBox(height: 2),
          Text(a.clientName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.client(14)),
          if (a.services.isNotEmpty) ...[
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              clipBehavior: Clip.hardEdge,
              children: [
                for (var i = 0; i < a.services.length; i++)
                  AppointmentServicePill(
                    name: a.services[i].name,
                    color: a.serviceColor(i),
                    foreground: foreground,
                  ),
              ],
            ),
          ],
          if (showStatus) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                StatusChip.appointment(a.status, dense: true),
                if (a.needsReschedule) StatusChip.toReschedule(dense: true),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Píldora de un servicio: punto con su color y su nombre. Sobre la tarjeta
/// de la agenda (fondo del color del servicio) es translúcida con
/// [foreground]; con [onSurface] (formulario y detalle de la cita, 12.07) se
/// tiñe con el color del servicio sobre la superficie del tema y es más
/// grande.
class AppointmentServicePill extends StatelessWidget {
  final String name;
  final Color color;
  final Color foreground;
  final bool onSurface;

  const AppointmentServicePill({
    super.key,
    required this.name,
    required this.color,
    required this.foreground,
    this.onSurface = false,
  });

  @override
  Widget build(BuildContext context) {
    final large = onSurface;
    return Container(
      padding: large
          ? const EdgeInsets.fromLTRB(6, 4, 10, 4)
          : const EdgeInsets.fromLTRB(4, 2, 8, 2),
      decoration: BoxDecoration(
        color: onSurface
            ? color.withValues(alpha: 0.14)
            : foreground.withValues(alpha: 0.16),
        borderRadius: AppRadii.chipRadius,
        border: Border.all(
            color: onSurface
                ? color.withValues(alpha: 0.45)
                : foreground.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: large ? 12 : 10,
            height: large ? 12 : 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                  color: onSurface ? color : foreground, width: 1.5),
            ),
          ),
          SizedBox(width: large ? 6 : 4),
          Flexible(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: foreground,
                fontSize: large ? 13 : 10.5,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Insignias de la esquina: por mover, reserva web, pago e iniciales de la
/// profesional.
class _Badges extends StatelessWidget {
  final AppointmentEntity appointment;
  final Color foreground;
  final double size;

  const _Badges({
    required this.appointment,
    required this.foreground,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final a = appointment;
    final iconSize = size * 0.72;
    Widget circle(Widget child) => Container(
          width: size,
          height: size,
          margin: const EdgeInsets.only(left: 3),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: foreground.withValues(alpha: 0.18),
            shape: BoxShape.circle,
          ),
          child: child,
        );
    final professional = a.professionalName;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (a.needsReschedule)
          circle(Icon(Icons.report_problem_rounded,
              size: iconSize, color: foreground, semanticLabel: 'Por mover')),
        if (a.isWebBooking)
          circle(Icon(Icons.public_rounded,
              size: iconSize, color: foreground, semanticLabel: 'Reserva web')),
        circle(Icon(StatusChip.paymentIcon(a.paymentStatus),
            size: iconSize,
            color: foreground,
            semanticLabel: a.paymentStatus.label)),
        if (professional != null && professional.trim().isNotEmpty)
          circle(Text(
            AppAvatar.initialsOf(professional),
            maxLines: 1,
            style: TextStyle(
              color: foreground,
              fontSize: size * 0.42,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          )),
      ],
    );
  }
}

/// Borde punteado de una cita "por mover".
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final BorderRadius radius;

  const _DashedBorderPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 2.0;
    final rect = (Offset.zero & size).deflate(stroke / 2);
    final path = Path()..addRRect(radius.toRRect(rect));
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    const dash = 5.0;
    const gap = 3.5;
    for (final ui.PathMetric metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += dash + gap) {
        canvas.drawPath(metric.extractPath(d, d + dash), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) =>
      old.color != color || old.radius != radius;
}
