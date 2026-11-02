import 'package:flutter/material.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/features/appointments/domain/entities/appointment_entity.dart';
import 'package:login_signup/shared/utils/color_hex.dart';
import 'package:login_signup/shared/widgets/status_chip.dart';

/// Texto y color del estado de una cita (la entidad no conoce Flutter). Los
/// textos e íconos canónicos están en `StatusChip` (shared, 12.03); los
/// colores, en `AppTokens` (modo oscuro incluido; `CONFIRMED` es teal).
extension AppointmentStatusUi on AppointmentStatus {
  String get label => StatusChip.appointmentLabel(this);

  ToneColors colorsOf(BuildContext context) =>
      context.tokens.appointmentStatus(this);
}

/// Texto y tono del estado de pago de una cita (`PARTIAL` = anticipo, 2.24).
extension AppointmentPaymentStatusUi on AppointmentPaymentStatus {
  String get label => StatusChip.paymentLabel(this);

  AppTone get tone => StatusChip.paymentTone(this);

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

/// Chip de estado de la cita o de su pago: el `StatusChip` compartido.
abstract final class AppointmentChip {
  /// Estado de la cita (`Pendiente`, `Confirmada`…).
  static Widget status(BuildContext context, AppointmentStatus s) =>
      StatusChip.appointment(s);

  /// Estado de pago (`Sin pagar`, `Anticipo`, `Pagada`…).
  static Widget payment(BuildContext context, AppointmentPaymentStatus s) =>
      StatusChip.payment(s);
}
