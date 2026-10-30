import 'package:get/get.dart';
import 'package:login_signup/features/settings/presentation/controllers/business_settings_controller.dart';

/// Solo el controller: datasource, repositorio y use cases los registra
/// `SettingsDependencies` (features/settings/settings_dependencies.dart).
class BusinessSettingsBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BusinessSettingsController>(
      () => BusinessSettingsController(
        getBusinessSettingsUseCase: Get.find(),
        updateBusinessTimeZoneUseCase: Get.find(),
        updateBusinessNameUseCase: Get.find(),
        updateOpeningHoursUseCase: Get.find(),
        session: Get.find(),
      ),
    );
  }
}
