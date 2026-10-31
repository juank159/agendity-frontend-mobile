import 'package:login_signup/core/sync/outbox_store.dart';
import 'package:login_signup/core/utils/date_codec.dart';
import 'package:login_signup/core/utils/formatters.dart';
import 'package:login_signup/core/utils/json_read.dart';

/// Textos de una operación de la bandeja para la pantalla "Pendientes"
/// (10.03): qué es, sobre qué y por qué no subió, en lenguaje humano.
abstract final class SyncEntryText {
  static const _actions = {
    'client.create': 'Cliente nuevo',
    'client.import': 'Contacto importado',
    'client.update': 'Cambio en un cliente',
    'client.delete': 'Borrado de un cliente',
    'appointment.create': 'Cita nueva',
    'appointment.update': 'Cambio en una cita',
    'appointment.cancel': 'Cancelación de una cita',
    'appointment.complete': 'Cita completada',
    'payment.create': 'Pago registrado',
    'payment.refund': 'Reembolso',
    'service.create': 'Servicio nuevo',
    'service.update': 'Cambio en un servicio',
    'service.delete': 'Borrado de un servicio',
    'category.create': 'Categoría nueva',
    'category.update': 'Cambio en una categoría',
    'category.delete': 'Borrado de una categoría',
  };

  /// "Cita nueva", "Pago registrado"…
  static String action(OutboxEntry entry) =>
      _actions[entry.type] ?? 'Cambio sin enviar';

  /// Detalle a partir de lo que se envía (nombre, fecha, monto), si lo hay.
  static String? detail(OutboxEntry entry) {
    final p = entry.payload;
    final name = [
      JsonRead.asOptionalString(p['name']),
      JsonRead.asOptionalString(p['lastname']),
    ].whereType<String>().join(' ');
    if (name.isNotEmpty) return name;
    final date = DateCodec.tryDecode(p['date']);
    if (date != null) {
      return '${formatWeekdayDayMonth(date)} · ${formatTime(date)}';
    }
    if (p['amount'] != null) return formatCop(p['amount']);
    if (p['refund_amount'] != null) return formatCop(p['refund_amount']);
    return null;
  }

  /// Por qué espera al usuario (o al envío), sin códigos técnicos.
  static String reason(OutboxEntry entry) {
    if (entry.status == OutboxStatus.pending) {
      return 'Se enviará al recuperar la conexión.';
    }
    switch (entry.code) {
      case 'TRIAL_LIMIT_REACHED':
        return 'Se acabaron las citas de la prueba. Compra un plan y se '
            'enviará sola.';
      case 'SUBSCRIPTION_INACTIVE':
        return 'El plan del negocio no está activo. Al renovarlo se enviará '
            'sola.';
      case 'NOT_FOUND':
        return 'Ya no existe en el servidor: alguien lo borró desde otro '
            'dispositivo.';
      case 'INVALID_STATE_TRANSITION':
        return 'La cita cambió en otro dispositivo (por ejemplo, ya estaba '
            'cancelada o completada).';
      case 'APPOINTMENT_PAID':
        return 'La cita tiene pagos: reembólsalos antes de cancelarla.';
      case 'FORBIDDEN':
        return 'Tu usuario no tiene permiso para este cambio.';
      case 'VALIDATION_ERROR':
      case 'BAD_REQUEST':
        final message = entry.message;
        return message == null || message.isEmpty
            ? 'El servidor no aceptó los datos.'
            : 'El servidor no aceptó los datos: $message';
      default:
        final message = entry.message;
        return message == null || message.isEmpty
            ? 'El servidor no aceptó este cambio.'
            : message;
    }
  }

  /// Rechazo que se arregla solo (plan o prueba): reintentar no es
  /// necesario, se reenvía en cada sincronización.
  static bool retriesBySelf(OutboxEntry entry) => entry.isTransientRejection;

  /// Qué se pierde al descartar (texto del diálogo de confirmación).
  static String discardWarning(OutboxEntry entry) {
    final what = action(entry).toLowerCase();
    final extra = detail(entry);
    return 'Se perderá "$what${extra == null ? '' : ' · $extra'}": lo que '
        'hiciste en este teléfono no llegará al servidor y se quitará de '
        'aquí. No se puede deshacer.';
  }
}
