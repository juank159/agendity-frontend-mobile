/// Cupo mensual de mensajes de WhatsApp (D-20/D-21: trial 10, planes 300).
class MessageQuota {
  /// `-1` = ilimitado.
  final int limit;
  final int used;

  /// Mes del cupo (`YYYY-MM`, en la zona del negocio).
  final String period;

  const MessageQuota({this.limit = 0, this.used = 0, this.period = ''});

  bool get isUnlimited => limit < 0;

  /// Lo que queda este mes (`null` si es ilimitado).
  int? get remaining =>
      isUnlimited ? null : (limit - used).clamp(0, limit < 0 ? 0 : limit);

  bool get isExhausted => !isUnlimited && used >= limit;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessageQuota &&
          other.limit == limit &&
          other.used == used &&
          other.period == period;

  @override
  int get hashCode => Object.hash(limit, used, period);
}

/// Recordatorios automáticos del negocio (Fase 11, solo Owner y con
/// conexión): encendidos o no y ventana de envío `[inicio, fin)` en hora del
/// negocio (`HH:mm`; inicio = fin es todo el día; inicio > fin cruza la
/// medianoche). [channel] (`log` simulado o `whatsapp_cloud`) y [quota] son
/// de solo lectura.
class ReminderSettings {
  final bool enabled;
  final String sendWindowStart;
  final String sendWindowEnd;
  final String channel;
  final MessageQuota quota;

  const ReminderSettings({
    this.enabled = false,
    this.sendWindowStart = '08:00',
    this.sendWindowEnd = '20:00',
    this.channel = 'log',
    this.quota = const MessageQuota(),
  });

  /// Canal simulado: los mensajes no salen de verdad (solo en el log).
  bool get isSimulated => channel == 'log';

  ReminderSettings copyWith({
    bool? enabled,
    String? sendWindowStart,
    String? sendWindowEnd,
  }) =>
      ReminderSettings(
        enabled: enabled ?? this.enabled,
        sendWindowStart: sendWindowStart ?? this.sendWindowStart,
        sendWindowEnd: sendWindowEnd ?? this.sendWindowEnd,
        channel: channel,
        quota: quota,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReminderSettings &&
          other.enabled == enabled &&
          other.sendWindowStart == sendWindowStart &&
          other.sendWindowEnd == sendWindowEnd &&
          other.channel == channel &&
          other.quota == quota;

  @override
  int get hashCode =>
      Object.hash(enabled, sendWindowStart, sendWindowEnd, channel, quota);
}
