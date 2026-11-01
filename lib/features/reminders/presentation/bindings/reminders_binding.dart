import 'package:get/get.dart';
import 'package:login_signup/features/reminders/presentation/controllers/reminder_history_controller.dart';
import 'package:login_signup/features/reminders/presentation/controllers/reminders_controller.dart';

/// "Recordatorios" (`/reminders`, solo Owner). Los use cases los registra
/// `RemindersDependencies`.
class RemindersBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<RemindersController>(
      () => RemindersController(
        getReminderSettingsUseCase: Get.find(),
        updateReminderSettingsUseCase: Get.find(),
        getReminderRulesUseCase: Get.find(),
        saveReminderRuleUseCase: Get.find(),
        deleteReminderRuleUseCase: Get.find(),
        previewReminderUseCase: Get.find(),
      ),
    );
  }
}

/// Historial de envíos (`/reminders/history`, solo Owner).
class ReminderHistoryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ReminderHistoryController>(
      () => ReminderHistoryController(getReminderDeliveriesUseCase: Get.find()),
    );
  }
}
