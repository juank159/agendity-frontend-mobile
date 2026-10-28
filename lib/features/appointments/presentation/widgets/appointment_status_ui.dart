import 'package:flutter/material.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/features/appointments/domain/entities/appointment_entity.dart';
import 'package:login_signup/features/services/presentation/widgets/color_picker.dart';

/// Texto y color del estado de una cita (la entidad no conoce Flutter). Los
/// colores salen de `AppTokens` (modo oscuro incluido; `CONFIRMED` es teal).
extension AppointmentStatusUi on AppointmentStatus {
  String get label => switch (this) {
        AppointmentStatus.PENDING => 'Pendiente',
        AppointmentStatus.CONFIRMED => 'Confirmado',
        AppointmentStatus.COMPLETED => 'Completado',
        AppointmentStatus.CANCELLED => 'Cancelado',
      };

  ToneColors colorsOf(BuildContext context) =>
      context.tokens.appointmentStatus(this);
}

/// Texto y tono del estado de pago de una cita (`PARTIAL` = anticipo, 2.24).
extension AppointmentPaymentStatusUi on AppointmentPaymentStatus {
  String get label => switch (this) {
        AppointmentPaymentStatus.PENDING => 'Pendiente',
        AppointmentPaymentStatus.PARTIAL => 'Anticipo',
        AppointmentPaymentStatus.COMPLETED => 'Pagado',
        AppointmentPaymentStatus.FAILED => 'Fallido',
        AppointmentPaymentStatus.REFUNDED => 'Reembolsado',
        AppointmentPaymentStatus.CANCELLED => 'Cancelado',
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
  Color serviceColor(int index) => colorFromHex(
      index < services.length ? services[index].color ?? '' : '');
}
