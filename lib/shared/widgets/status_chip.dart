import 'package:flutter/material.dart';
import 'package:login_signup/common/enums/appointment_payment_status_enum.dart';
import 'package:login_signup/common/enums/appointment_status_enum.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/shared/widgets/app_pill.dart';

/// Chip de estado de la guía (§3): color de estado, ícono y texto, radio 12
/// (la píldora es `AppPill`; aquí, los colores y la semántica "Estado: …").
/// Los colores salen de `AppTokens` (no cambian con la paleta).
///
/// Textos e íconos **canónicos** de los estados de cita y de pago: los usan
/// también las extensiones de `appointment_status_ui.dart`.
class StatusChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final ToneColors Function(AppTokens tokens) _colors;

  /// Más bajo (dentro de tarjetas de cita).
  final bool dense;

  StatusChip({
    super.key,
    required this.label,
    required ToneColors colors,
    this.icon,
    this.dense = false,
  }) : _colors = ((_) => colors);

  /// Estado de una cita: "Pendiente", "Confirmada", "Completada", "Cancelada".
  StatusChip.appointment(AppointmentStatus status,
      {super.key, this.dense = false})
      : label = appointmentLabel(status),
        icon = appointmentIcon(status),
        _colors = ((tokens) => tokens.appointmentStatus(status));

  /// Estado de pago de una cita: "Sin pagar", "Anticipo", "Pagada"…
  StatusChip.payment(AppointmentPaymentStatus status,
      {super.key, this.dense = false})
      : label = paymentLabel(status),
        icon = paymentIcon(status),
        _colors = ((tokens) => tokens.tone(paymentTone(status)));

  /// Cita que chocó al sincronizar y hay que mover (10.03).
  StatusChip.toReschedule({super.key, this.dense = false})
      : label = 'Por mover',
        icon = Icons.event_repeat_rounded,
        _colors = ((tokens) => tokens.warning);

  static String appointmentLabel(AppointmentStatus status) => switch (status) {
        AppointmentStatus.PENDING => 'Pendiente',
        AppointmentStatus.CONFIRMED => 'Confirmada',
        AppointmentStatus.COMPLETED => 'Completada',
        AppointmentStatus.CANCELLED => 'Cancelada',
      };

  static IconData appointmentIcon(AppointmentStatus status) => switch (status) {
        AppointmentStatus.PENDING => Icons.schedule_rounded,
        AppointmentStatus.CONFIRMED => Icons.event_available_rounded,
        AppointmentStatus.COMPLETED => Icons.check_circle_rounded,
        AppointmentStatus.CANCELLED => Icons.cancel_rounded,
      };

  static String paymentLabel(AppointmentPaymentStatus status) =>
      switch (status) {
        AppointmentPaymentStatus.PENDING => 'Sin pagar',
        AppointmentPaymentStatus.PARTIAL => 'Anticipo',
        AppointmentPaymentStatus.COMPLETED => 'Pagada',
        AppointmentPaymentStatus.FAILED => 'Pago fallido',
        AppointmentPaymentStatus.REFUNDED => 'Reembolsada',
        AppointmentPaymentStatus.CANCELLED => 'Pago cancelado',
      };

  static AppTone paymentTone(AppointmentPaymentStatus status) =>
      switch (status) {
        AppointmentPaymentStatus.PENDING => AppTone.warning,
        AppointmentPaymentStatus.PARTIAL => AppTone.info,
        AppointmentPaymentStatus.COMPLETED => AppTone.success,
        AppointmentPaymentStatus.REFUNDED => AppTone.info,
        AppointmentPaymentStatus.FAILED ||
        AppointmentPaymentStatus.CANCELLED =>
          AppTone.error,
      };

  static IconData paymentIcon(AppointmentPaymentStatus status) =>
      switch (status) {
        AppointmentPaymentStatus.PENDING => Icons.money_off_rounded,
        AppointmentPaymentStatus.PARTIAL => Icons.timelapse_rounded,
        AppointmentPaymentStatus.COMPLETED => Icons.paid_rounded,
        AppointmentPaymentStatus.REFUNDED => Icons.undo_rounded,
        AppointmentPaymentStatus.FAILED ||
        AppointmentPaymentStatus.CANCELLED =>
          Icons.error_outline_rounded,
      };

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Estado: $label',
      excludeSemantics: true,
      child: AppPill(
        label: label,
        icon: icon,
        colors: _colors(context.tokens),
        dense: dense,
      ),
    );
  }
}
