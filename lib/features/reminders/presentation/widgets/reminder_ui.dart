import 'package:flutter/material.dart';
import 'package:login_signup/core/config/theme_config.dart';
import 'package:login_signup/features/reminders/domain/entities/reminder_delivery.dart';
import 'package:login_signup/features/reminders/domain/entities/reminder_rule.dart';

/// Textos e iconos de los recordatorios (Fase 11).
extension ReminderKindUi on ReminderKind {
  String get label => switch (this) {
        ReminderKind.beforeAppointment => 'Antes de la cita',
        ReminderKind.maintenance => 'Mantenimiento',
        ReminderKind.birthday => 'Cumpleaños',
        ReminderKind.winBack => 'Te extrañamos',
      };

  String get explanation => switch (this) {
        ReminderKind.beforeAppointment =>
          'Avisa al cliente un rato antes de su cita. Puedes tener varios '
              '(por ejemplo, 24 horas y 1 hora antes).',
        ReminderKind.maintenance =>
          'Cuando pasan los días de mantenimiento de un servicio (se ponen '
              'en cada servicio), invita al cliente a volver.',
        ReminderKind.birthday =>
          'Felicita al cliente el día de su cumpleaños (si lo tiene en su '
              'ficha).',
        ReminderKind.winBack =>
          'Escribe al cliente que lleva un tiempo sin venir.',
      };

  IconData get icon => switch (this) {
        ReminderKind.beforeAppointment => Icons.alarm_rounded,
        ReminderKind.maintenance => Icons.autorenew_rounded,
        ReminderKind.birthday => Icons.cake_rounded,
        ReminderKind.winBack => Icons.favorite_rounded,
      };

  /// Solo el de cita admite varias reglas; los otros, una por negocio.
  bool get allowsSeveral => this == ReminderKind.beforeAppointment;
}

/// "30 min antes", "2 h antes", "1 día antes".
String minutesBeforeLabel(int minutes) {
  if (minutes % 1440 == 0) {
    final days = minutes ~/ 1440;
    return days == 1 ? '1 día antes' : '$days días antes';
  }
  if (minutes % 60 == 0) return '${minutes ~/ 60} h antes';
  if (minutes > 60) return '${minutes ~/ 60} h ${minutes % 60} min antes';
  return '$minutes min antes';
}

extension DeliveryStatusUi on DeliveryStatus {
  String get label => switch (this) {
        DeliveryStatus.queued => 'En cola',
        DeliveryStatus.sent => 'Enviado',
        DeliveryStatus.delivered => 'Entregado',
        DeliveryStatus.read => 'Leído',
        DeliveryStatus.failed => 'Falló',
        DeliveryStatus.skipped => 'No se envió',
      };

  AppTone get tone => switch (this) {
        DeliveryStatus.queued => AppTone.info,
        DeliveryStatus.sent ||
        DeliveryStatus.delivered ||
        DeliveryStatus.read =>
          AppTone.success,
        DeliveryStatus.failed => AppTone.error,
        DeliveryStatus.skipped => AppTone.warning,
      };

  IconData get icon => switch (this) {
        DeliveryStatus.queued => Icons.schedule_send_rounded,
        DeliveryStatus.sent => Icons.check_rounded,
        DeliveryStatus.delivered => Icons.done_all_rounded,
        DeliveryStatus.read => Icons.mark_chat_read_rounded,
        DeliveryStatus.failed => Icons.error_rounded,
        DeliveryStatus.skipped => Icons.do_not_disturb_on_rounded,
      };
}

/// Motivo de un envío que no salió, en lenguaje humano.
String deliveryReasonLabel(String? reason) => switch (reason) {
      null => '',
      DeliveryReason.quota =>
        'Se agotaron los mensajes del mes. Envíalo a mano desde la cita.',
      DeliveryReason.noConsent =>
        'El cliente no ha aceptado recibir mensajes por WhatsApp.',
      DeliveryReason.optedOut => 'El cliente se dio de baja de los mensajes.',
      DeliveryReason.invalidPhone => 'El teléfono del cliente no es válido.',
      DeliveryReason.tooLate =>
        'Ya era tarde para enviarlo (fuera del horario de envío o la cita ya '
            'pasó).',
      DeliveryReason.bookedAfter =>
        'La cita se agendó después de la hora de este recordatorio.',
      DeliveryReason.appointmentChanged =>
        'La cita cambió (se movió o se canceló).',
      DeliveryReason.ruleDisabled => 'El recordatorio estaba desactivado.',
      DeliveryReason.remindersDisabled =>
        'Los recordatorios del negocio estaban apagados.',
      DeliveryReason.alreadyBooked => 'El cliente ya tenía una cita agendada.',
      DeliveryReason.stale => 'Se quedó sin enviar demasiado tiempo.',
      DeliveryReason.maxAttempts =>
        'No se pudo enviar después de varios intentos.',
      DeliveryReason.provider => 'WhatsApp no lo aceptó.',
      _ => 'Motivo: $reason',
    };
