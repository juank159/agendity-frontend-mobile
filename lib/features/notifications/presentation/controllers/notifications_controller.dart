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
      _worker =
          Get.find<SyncController>().onDataChanged(() => load(silent: true));
    }
    load();
  }

  @override
  void onClose() {
    _worker?.dispose();
    super.onClose();
  }

  /// [silent] (recarga tras una sincronización, 7.05d): sin indicador de
  /// carga y, si falla con datos ya cargados, se conservan sin mostrar el
  /// error.
  Future<void> load({bool silent = false}) async {
    if (!silent) {
      isLoading.value = true;
      error.value = null;
    }
    final result = await _getNotifications(NoParams());
    if (!silent) isLoading.value = false;
    result.fold((failure) {
      if (!silent || notifications.isEmpty) error.value = failure;
    }, (loaded) {
      error.value = null;
      notifications.assignAll(loaded);
    });
  }

  Future<void> refreshFromServer() async {
    if (Get.isRegistered<SyncController>()) {
      await Get.find<SyncController>().syncNow();
    }
    await load();
  }
}
