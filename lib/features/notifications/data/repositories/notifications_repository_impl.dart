import 'package:dartz/dartz.dart';
import 'package:login_signup/core/database/document_store.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/network/safe_call.dart';
import 'package:login_signup/core/sync/offline_store.dart';
import 'package:login_signup/features/notifications/data/models/app_notification_model.dart';
import 'package:login_signup/features/notifications/domain/entities/app_notification.dart';
import 'package:login_signup/features/notifications/domain/repositories/notifications_repository.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  final OfflineStore _store;

  NotificationsRepositoryImpl(this._store);

  @override
  Future<Either<Failure, List<AppNotification>>> getNotifications() =>
      safeCall(() async => [
            for (final doc in (await DocumentStore.list(
                    await _store.database(), AppNotificationModel.kind.entity))
                .reversed)
              AppNotificationModel.fromJson(doc),
          ]);
}
