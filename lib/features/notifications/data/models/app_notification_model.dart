import 'package:login_signup/core/database/document_store.dart';
import 'package:login_signup/core/utils/date_codec.dart';
import 'package:login_signup/core/utils/json_read.dart';
import 'package:login_signup/features/notifications/domain/entities/app_notification.dart';

/// DTO de `notifications` (feed de sincronización, forma de la API).
abstract final class AppNotificationModel {
  static const kind = DocumentKind('notifications', at: _createdAt);

  static Object? _createdAt(Map<String, dynamic> d) => d['created_at'];

  static AppNotification fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: JsonRead.asString(json['id']),
        type: JsonRead.asString(json['type']),
        title: JsonRead.asString(json['title']),
        message: JsonRead.asString(json['message']),
        read: JsonRead.asBool(json['read'], fallback: false),
        createdAt: DateCodec.tryDecode(json['created_at']),
        metadata: JsonRead.asMap(json['metadata']) ?? const {},
      );
}
