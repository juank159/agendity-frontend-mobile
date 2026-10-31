import 'package:get/get.dart';
import 'package:login_signup/core/errors/failures.dart';
import 'package:login_signup/core/usecases/usecase.dart';
import 'package:login_signup/features/notifications/domain/entities/app_notification.dart';
import 'package:login_signup/features/notifications/domain/usecases/get_notifications_usecase.dart';
import 'package:login_signup/shared/controllers/sync_controller.dart';

/// Avisos del usuario (10.03; backend `notifications`, p. ej. el
/// recordatorio automático de una cita, D-05). Solo lectura.
class NotificationsController extends GetxController {
  final GetNotificationsUseCase _getNotifications;

  NotificationsController(
      {required GetNotificationsUseCase getNotificationsUseCase})
      : _getNotifications = getNotificationsUseCase;

  final notifications = <AppNotification>[].obs;
  final isLoading = false.obs;
  final error = Rxn<Failure>();
  Worker? _worker;

  @override
  void onInit() {
    super.onInit();
    if (Get.isRegistered<SyncController>()) {
      _worker = Get.find<SyncController>().onDataChanged(load);
    }
    load();
  }

  @override
  void onClose() {
    _worker?.dispose();
    super.onClose();
  }

  Future<void> load() async {
    isLoading.value = true;
    error.value = null;
    final result = await _getNotifications(NoParams());
    isLoading.value = false;
    result.fold((failure) => error.value = failure, notifications.assignAll);
  }

  Future<void> refreshFromServer() async {
    if (Get.isRegistered<SyncController>()) {
      await Get.find<SyncController>().syncNow();
    }
    await load();
  }
}
