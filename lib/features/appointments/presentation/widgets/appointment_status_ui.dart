import 'package:flutter/material.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/features/appointments/domain/entities/appointment_entity.dart';
import 'package:login_signup/shared/utils/color_hex.dart';

/// Texto y color del estado de una cita (la entidad no conoce Flutter). Los
/// colores salen de `AppTokens` (modo oscuro incluido; `CONFIRMED` es teal).
extension AppointmentStatusUi on AppointmentStatus {
  String get label => switch (this) {
        AppointmentStatus.PENDING => 'Pendiente',
        AppointmentStatus.CONFIRMED => 'Confirmada',
        AppointmentStatus.COMPLETED => 'Completada',
        AppointmentStatus.CANCELLED => 'Cancelada',
      };

  ToneColors colorsOf(BuildContext context) =>
      context.tokens.appointmentStatus(this);
}

/// Texto y tono del estado de pago de una cita (`PARTIAL` = anticipo, 2.24).
extension AppointmentPaymentStatusUi on AppointmentPaymentStatus {
  String get label => switch (this) {
        AppointmentPaymentStatus.PENDING => 'Sin pagar',
        AppointmentPaymentStatus.PARTIAL => 'Anticipo',
        AppointmentPaymentStatus.COMPLETED => 'Pagada',
        AppointmentPaymentStatus.FAILED => 'Pago fallido',
        AppointmentPaymentStatus.REFUNDED => 'Reembolsada',
        AppointmentPaymentStatus.CANCELLED => 'Pago cancelado',
      };

  AppTone get tone => switch (this) {
        AppointmentPaymentStatus.PENDING => AppTone.warning,
        AppointmentPaymentStatus.PARTIAL => AppTone.info,
        AppointmentPaymentStatus.COMPLETED => AppTone.success,
        AppointmentPaymentStatus.REFUNDED => AppTone.info,
        AppointmentPaymentStatus.FAILED ||
        AppointmentPaymentStatus.CANCELLED =>
          AppTone.error,
      };

  ToneColors colorsOf(BuildContext context) => context.tokens.tone(tone);
}

/// Colores de los servicios de una cita (hex del catálogo → `Color`).
extension AppointmentColorsUi on AppointmentEntity {
  /// Color del primer servicio (el de la cita en el calendario).
  Color get primaryColor => serviceColor(0);

  /// Color del servicio [index]; sin color, el por defecto de servicios.
  Color serviceColor(int index) =>
      colorFromHex(index < services.length ? services[index].color : null);
}

/// Etiqueta con fondo suave para un estado (de la cita o de su pago).
class AppointmentChip extends StatelessWidget {
  final String label;
  final ToneColors colors;

  const AppointmentChip({super.key, required this.label, required this.colors});

  /// Estado de la cita (`Pendiente`, `Confirmada`…).
  factory AppointmentChip.status(BuildContext context, AppointmentStatus s) =>
      AppointmentChip(label: s.label, colors: s.colorsOf(context));

  /// Estado de pago (`Sin pagar`, `Anticipo`, `Pagada`…).
  factory AppointmentChip.payment(
          BuildContext context, AppointmentPaymentStatus s) =>
      AppointmentChip(label: s.label, colors: s.colorsOf(context));

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.container,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: colors.onContainer,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
