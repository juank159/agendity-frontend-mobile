import 'package:get/get.dart';
import 'package:login_signup/core/sync/document_sync_handler.dart';
import 'package:login_signup/core/sync/offline_store.dart';
import 'package:login_signup/core/sync/sync_engine.dart';
import 'package:login_signup/features/notifications/data/models/app_notification_model.dart';
import 'package:login_signup/features/notifications/data/repositories/notifications_repository_impl.dart';
import 'package:login_signup/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:login_signup/features/notifications/domain/usecases/get_notifications_usecase.dart';

/// Avisos del usuario (10.02b): solo bajada. Pantalla: pestaña "Avisos"
/// de la campana (10.03).
abstract final class NotificationsDependencies {
  static void init() {
    Get.find<SyncEngine>()
        .register(DocumentSyncHandler(AppNotificationModel.kind));
    Get.lazyPut<NotificationsRepository>(
        () => NotificationsRepositoryImpl(Get.find<OfflineStore>()),
        fenix: true);
    Get.lazyPut(
        () => GetNotificationsUseCase(Get.find<NotificationsRepository>()),
        fenix: true);
  }
}
