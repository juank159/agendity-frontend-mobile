import 'package:login_signup/core/utils/date_codec.dart';
import 'package:login_signup/core/utils/json_read.dart';
import 'package:login_signup/features/reminders/domain/entities/reminder_delivery.dart';
import 'package:login_signup/features/reminders/domain/entities/reminder_rule.dart';
import 'package:login_signup/features/reminders/domain/entities/reminder_settings.dart';

/// DTO de `GET`/`PUT /reminders/settings` (snake_case; `quota` anidado).
abstract final class ReminderSettingsModel {
  static ReminderSettings fromJson(Map<String, dynamic> json) {
    final quota = JsonRead.asMap(json['quota']) ?? const {};
    return ReminderSettings(
      enabled: JsonRead.asBool(json['enabled'], fallback: false),
      sendWindowStart:
          JsonRead.asOptionalString(json['send_window_start']) ?? '08:00',
      sendWindowEnd: JsonRead.asOptionalString(json['send_window_end']) ?? '20:00',
      channel: JsonRead.asOptionalString(json['channel']) ?? 'log',
      quota: MessageQuota(
        limit: JsonRead.asInt(quota['limit']),
        used: JsonRead.asInt(quota['used']),
        period: JsonRead.asString(quota['period']),
      ),
    );
  }

  /// Cuerpo del `PUT` (`UpdateReminderSettingsDto`: sin canal ni cupo).
  static Map<String, dynamic> toJson(ReminderSettings settings) => {
        'enabled': settings.enabled,
        'send_window_start': settings.sendWindowStart,
        'send_window_end': settings.sendWindowEnd,
      };
}

/// DTO de `/reminders/rules` (snake_case). Sin un `kind` conocido no es una
/// regla (`FormatException` → `ServerFailure`).
abstract final class ReminderRuleModel {
  static ReminderRule fromJson(Map<String, dynamic> json) {
    final kind = ReminderKind.fromApi(json['kind']);
    if (kind == null) throw const FormatException('Regla sin tipo conocido');
    int? optionalInt(Object? value) =>
        value == null ? null : JsonRead.asInt(value);
    return ReminderRule(
      id: JsonRead.asOptionalString(json['id']),
      kind: kind,
      isActive: JsonRead.asBool(json['is_active'], fallback: true),
      minutesBefore: optionalInt(json['minutes_before']),
      daysWithoutVisit: optionalInt(json['days_without_visit']),
      sendTime: _hhmm(JsonRead.asOptionalString(json['send_time'])),
      template: JsonRead.asString(json['template']),
      category: ReminderCategory.fromApi(json['category']),
      metaTemplateName: JsonRead.asOptionalString(json['meta_template_name']),
    );
  }

  /// `"10:00:00"` (columna `time`) → `"10:00"`.
  static String? _hhmm(String? value) =>
      value != null && value.length >= 5 ? value.substring(0, 5) : value;

  /// Cuerpo de `POST` (con `kind`) o `PATCH` (sin `kind`: no se cambia).
  /// Solo los campos de su tipo; plantilla vacía = la del tipo.
  static Map<String, dynamic> toJson(ReminderRule rule, {required bool create}) {
    final before = rule.kind == ReminderKind.beforeAppointment;
    return {
      if (create) 'kind': rule.kind.apiValue,
      'is_active': rule.isActive,
      if (before) 'minutes_before': rule.minutesBefore,
      if (rule.kind == ReminderKind.winBack)
        'days_without_visit': rule.daysWithoutVisit,
      if (!before && rule.sendTime != null) 'send_time': rule.sendTime,
      if (rule.template.trim().isNotEmpty) 'template': rule.template.trim(),
      'category': rule.category.apiValue,
      if (rule.metaTemplateName != null)
        'meta_template_name': rule.metaTemplateName,
    };
  }
}

/// DTO de `GET /reminders/deliveries` (camelCase, la entidad del backend).
abstract final class ReminderDeliveryModel {
  static ReminderDelivery fromJson(Map<String, dynamic> json) =>
      ReminderDelivery(
        id: JsonRead.asString(json['id']),
        kind: ReminderKind.fromApi(json['kind']),
        status:
            DeliveryStatus.fromApi(json['status']) ?? DeliveryStatus.queued,
        reason: JsonRead.asOptionalString(json['reason']),
        clientId: JsonRead.asOptionalString(json['clientId']),
        appointmentId: JsonRead.asOptionalString(json['appointmentId']),
        category: ReminderCategory.fromApi(json['category']),
        phone: JsonRead.asOptionalString(json['phone']),
        body: JsonRead.asOptionalString(json['body']),
        attempts: JsonRead.asInt(json['attempts']),
        scheduledFor: DateCodec.tryDecode(json['scheduledFor']),
        sentAt: DateCodec.tryDecode(json['sentAt']),
        deliveredAt: DateCodec.tryDecode(json['deliveredAt']),
        readAt: DateCodec.tryDecode(json['readAt']),
        failedAt: DateCodec.tryDecode(json['failedAt']),
        createdAt: DateCodec.tryDecode(json['createdAt']),
      );
}
